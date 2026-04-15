@Tags(['golden'])
library;

// ── Golden tests — HomeScreen (multi-device) ──────────────────────────────
//
// Covers 3 states × 8 devices = 24 goldens.
//
// Devices tested:
//   iOS    : iPhone SE 3, iPhone 16, iPhone 16 Pro Max
//   Android: Galaxy S24, Galaxy S24 Ultra, Pixel 9
//   Web    : laptop 1280×800, desktop 1920×1080
//
// GENERATE reference files (macOS CI):
//   flutter test test/golden/ --update-goldens --tags golden
//
// VERIFY (macOS CI):
//   flutter test test/golden/ --tags golden
//
// IMPORTANT: goldens are tied to the rendering platform (macOS ≠ Linux).
// Always generate and validate on macOS (workflow "Update Golden Screenshots").

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/app/theme.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/screens/home_screen.dart';

// ── Devices ───────────────────────────────────────────────────────────────

class _Device {
  const _Device(this.id, this.logicalWidth, this.logicalHeight, this.ratio);

  /// Short identifier used in the golden filename.
  final String id;
  final double logicalWidth;
  final double logicalHeight;

  /// devicePixelRatio (physical pixels / logical pixels).
  final double ratio;

  Size get physical => Size(logicalWidth * ratio, logicalHeight * ratio);
}

/// Most popular mobile devices in 2025 + common web breakpoints.
const List<_Device> _devices = [
  // ── iOS ──────────────────────────────────────────────────────────────
  _Device('iphone_se3',        375,  667, 2.0),  // iPhone SE 3rd gen
  _Device('iphone_16',         390,  844, 3.0),  // iPhone 16
  _Device('iphone_16_pro_max', 440,  956, 3.0),  // iPhone 16 Pro Max
  // ── Android ──────────────────────────────────────────────────────────
  _Device('galaxy_s24',        360,  780, 3.0),  // Samsung Galaxy S24
  _Device('galaxy_s24_ultra',  412,  932, 3.5),  // Samsung Galaxy S24 Ultra
  _Device('pixel_9',           412,  892, 2.75), // Google Pixel 9
  // ── Web ──────────────────────────────────────────────────────────────
  _Device('web_laptop',       1280,  800, 1.0),  // Laptop 1280×800
  _Device('web_desktop',      1920, 1080, 1.0),  // Desktop 1920×1080
];

// ── Mock ──────────────────────────────────────────────────────────────────

class MockAssistantBloc
    extends MockBloc<AssistantEvent, AssistantState>
    implements AssistantBloc {}

// ── Helpers ───────────────────────────────────────────────────────────────

/// Creates a MockBloc fixed in [state], with no transitions.
MockAssistantBloc _blocWith(AssistantState state) {
  final bloc = MockAssistantBloc();
  whenListen(
    bloc,
    Stream<AssistantState>.empty(),
    initialState: state,
  );
  return bloc;
}

Widget _buildApp(AssistantBloc bloc) => BlocProvider<AssistantBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );

void _setDevice(WidgetTester tester, _Device device) {
  tester.view.physicalSize = device.physical;
  tester.view.devicePixelRatio = device.ratio;
}

void _resetDevice(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Future<void> _loadFonts() async {
  final interLoader = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  
  await interLoader.load();

  final materialIconsLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('assets/fonts/MaterialIcons-Regular.otf'));

  await materialIconsLoader.load();
}

// ── Tests ─────────────────────────────────────────────────────────────────

// ── Fake HTTP for network image loading in golden tests ───────────────────

/// PNG bytes generated once per test run.
late Uint8List _fakePng;

/// Generates a portrait 300×450 blue PNG using dart:ui so the golden shows a
/// real constrained image rather than a broken-image placeholder.
Future<Uint8List> _generateFakePng() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
    recorder,
    const ui.Rect.fromLTWH(0, 0, 300, 450),
  );
  // Draw a rounded blue rectangle that looks like a photo placeholder.
  final paint = ui.Paint()..color = const ui.Color(0xFF4A90D9);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 300, 450), paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(300, 450);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();

  // Unused methods — image loading only calls getUrl/openUrl.
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials cred) {}
  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials cred) {}
  @override
  set authenticate(
      Future<bool> Function(Uri, String, String?)? f) {}
  @override
  set authenticateProxy(
      Future<bool> Function(String, int, String, String?)? f) {}
  @override
  set badCertificateCallback(
      bool Function(X509Certificate, String, int)? cb) {}
  @override
  void close({bool force = false}) {}
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      throw UnimplementedError();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => throw UnimplementedError();
  @override
  set findProxy(String Function(Uri)? f) {}
  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      throw UnimplementedError();
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      throw UnimplementedError();
  @override
  Future<HttpClientRequest> headUrl(Uri url) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      throw UnimplementedError();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      throw UnimplementedError();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      throw UnimplementedError();
  @override
  Future<HttpClientRequest> postUrl(Uri url) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      throw UnimplementedError();
  @override
  Future<HttpClientRequest> putUrl(Uri url) => throw UnimplementedError();
  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(Uri, String?, int?)? f) {}
  @override
  set keyLog(Function(String)? callback) {}
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeRequestHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  bool bufferOutput = true;
  @override
  int contentLength = -1;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  String get method => 'GET';
  @override
  Uri get uri => Uri.parse('https://example.com/photo.jpg');

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> flush() async {}
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = '']) {}
  @override
  Future<HttpClientResponse> get done async => _FakeHttpClientResponse();
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => const [];
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _fakePng.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  HttpHeaders get headers => _FakeResponseHeaders();
  @override
  List<Cookie> get cookies => const [];
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  X509Certificate? get certificate => null;
  @override
  Future<Socket> detachSocket() => throw UnimplementedError();
  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      throw UnimplementedError();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.fromIterable([_fakePng]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}

class _FakeRequestHeaders implements HttpHeaders {
  final _map = <String, List<String>>{};

  @override
  List<String>? operator [](String name) => _map[name.toLowerCase()];
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _map.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }
  @override
  void forEach(void Function(String, List<String>) f) => _map.forEach(f);
  @override
  String? value(String name) {
    final v = _map[name.toLowerCase()];
    return (v == null || v.isEmpty) ? null : v.single;
  }
  @override void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name.toLowerCase()] = [value.toString()];
  }
  @override void remove(String name, Object value) {}
  @override void removeAll(String name) => _map.remove(name.toLowerCase());
  @override void noFolding(String name) {}
  @override void clear() => _map.clear();

  @override bool chunkedTransferEncoding = false;
  @override ContentType? contentType;
  @override int contentLength = -1;
  @override bool persistentConnection = true;
  @override DateTime? date;
  @override DateTime? expires;
  @override DateTime? ifModifiedSince;
  @override String? host;
  @override int? port;
}

class _FakeResponseHeaders implements HttpHeaders {
  @override List<String>? operator [](String name) => null;
  @override void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override void forEach(void Function(String, List<String>) f) {}
  @override String? value(String name) => null;
  @override void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override void remove(String name, Object value) {}
  @override void removeAll(String name) {}
  @override void noFolding(String name) {}
  @override void clear() {}

  @override bool chunkedTransferEncoding = false;
  @override ContentType? get contentType => null;
  @override set contentType(ContentType? v) {}
  @override int get contentLength => _fakePng.length;
  @override set contentLength(int v) {}
  @override bool persistentConnection = false;
  @override DateTime? date;
  @override DateTime? expires;
  @override DateTime? ifModifiedSince;
  @override String? host;
  @override int? port;
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await _loadFonts();
  });

  // ── Idle state ──────────────────────────────────────────────────────────
  
  group('HomeScreen — idle', () {
    for (final device in _devices) {
      testWidgets(device.id, (tester) async {
        _setDevice(tester, device);
        addTearDown(() => _resetDevice(tester));

        final bloc = _blocWith(const AssistantState.idle());
        addTearDown(bloc.close);

        await tester.pumpWidget(_buildApp(bloc));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_idle_${device.id}.png'),
        );
      });
    }
  });

  // ── Starting state ──────────────────────────────────────────────────────────

  group('HomeScreen — starting', () {
    for (final device in _devices) {
      testWidgets(device.id, (tester) async {
        _setDevice(tester, device);
        addTearDown(() => _resetDevice(tester));

        final bloc = _blocWith(const AssistantState.starting());
        addTearDown(bloc.close);

        await tester.pumpWidget(_buildApp(bloc));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_starting_${device.id}.png'),
        );
      });
    }
  });

  // ── Speaking state ──────────────────────────────────────────────────────

  group('HomeScreen — speaking', () {
    for (final device in _devices) {
      testWidgets(device.id, (tester) async {
        _setDevice(tester, device);
        addTearDown(() => _resetDevice(tester));

        final bloc = _blocWith(
          const AssistantState.speaking(
            responseText:
                'Vos médicaments sont dans l\'armoire à pharmacie, dans la salle de bain.',
          ),
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(_buildApp(bloc));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_speaking_${device.id}.png'),
        );
      });
    }
  });

  // ── Speaking state with image ───────────────────────────────────────────
  //
  // Verifies that a portrait image (300×450 px) is clipped to maxHeight=220
  // and does not cause overflow on any device.

  group('HomeScreen — speaking with image', () {
    setUpAll(() async {
      _fakePng = await _generateFakePng();
    });

    setUp(() => HttpOverrides.global = _FakeHttpOverrides());
    tearDown(() => HttpOverrides.global = null);

    for (final device in _devices) {
      testWidgets(device.id, (tester) async {
        _setDevice(tester, device);
        addTearDown(() => _resetDevice(tester));

        final bloc = _blocWith(
          const AssistantState.speaking(
            imageUrl: 'https://example.com/photo.jpg',
          ),
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(_buildApp(bloc));
        // Step out of fakeAsync so the fake HTTP response can complete.
        await tester.runAsync(() async {
          await Future<void>.delayed(Duration.zero);
        });
        // Let the image decode and the slide-in animation finish (350 ms).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_speaking_image_${device.id}.png'),
        );
      });
    }
  });
}
