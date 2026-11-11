import 'dart:convert';
import 'dart:io';

import 'package:alzheimer_assistant/features/life_stories/data/repositories/http_life_story_settings_repository.dart';
import 'package:alzheimer_assistant/features/life_stories/domain/entities/life_story_settings.dart';
import 'package:flutter_test/flutter_test.dart';

class _Request {
  const _Request(this.method, this.uri, this.headers, this.body);

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

void main() {
  test('fetch() reads the settings with the access token', () async {
    final requests = <_Request>[];
    final repo = HttpLifeStorySettingsRepository(
      httpFn: (method, uri, headers, body) async {
        requests.add(_Request(method, uri, headers, body));
        return jsonEncode({'capture_enabled': true, 'keep_audio': false});
      },
      accessTokenProvider: () => 'jwt-123',
      supabaseUserIdProvider: () => 'user-1',
    );

    final settings = await repo.fetch();

    expect(
      settings,
      const LifeStorySettings(captureEnabled: true, keepAudio: false),
    );
    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.uri.path, endsWith('/life-stories/settings'));
    expect(request.uri.queryParameters, {'supabase_user_id': 'user-1'});
    expect(request.headers, {'Authorization': 'Bearer jwt-123'});
    expect(request.body, isNull);
  });

  test('save() sends the settings and returns what the server stored', () async {
    final requests = <_Request>[];
    final repo = HttpLifeStorySettingsRepository(
      httpFn: (method, uri, headers, body) async {
        requests.add(_Request(method, uri, headers, body));
        // The server turns the voice off when capture is off.
        return jsonEncode({'capture_enabled': false, 'keep_audio': false});
      },
      accessTokenProvider: () => 'jwt-123',
    );

    final saved = await repo.save(
      const LifeStorySettings(captureEnabled: false, keepAudio: true),
    );

    expect(saved, const LifeStorySettings());
    final request = requests.single;
    expect(request.method, 'PUT');
    expect(request.uri.path, endsWith('/life-stories/settings'));
    expect(jsonDecode(request.body!), {
      'capture_enabled': false,
      'keep_audio': true,
    });
  });

  test('omits the user id and auth header when signed out', () async {
    final requests = <_Request>[];
    final repo = HttpLifeStorySettingsRepository(
      httpFn: (method, uri, headers, body) async {
        requests.add(_Request(method, uri, headers, body));
        return '{}';
      },
    );

    expect(await repo.fetch(), const LifeStorySettings());
    expect(requests.single.uri.queryParameters, isEmpty);
    expect(requests.single.headers, isEmpty);
  });

  test('propagates server errors', () async {
    final repo = HttpLifeStorySettingsRepository(
      httpFn: (_, uri, _, _) async =>
          throw HttpException('Server error 502', uri: uri),
    );

    expect(repo.fetch(), throwsA(isA<HttpException>()));
    expect(
      repo.save(const LifeStorySettings()),
      throwsA(isA<HttpException>()),
    );
  });
}
