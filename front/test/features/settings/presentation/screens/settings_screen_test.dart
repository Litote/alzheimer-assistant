import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_assistant/features/life_stories/domain/entities/life_story_settings.dart';
import 'package:alzheimer_assistant/features/life_stories/domain/repositories/life_story_settings_repository.dart';
import 'package:alzheimer_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';

class _FakeSettingsService implements SettingsService {
  bool elevenLabs;
  bool textMode;
  bool liveKit;

  _FakeSettingsService({
    bool initial = false,
    bool textModeInitial = false,
    bool liveKitInitial = false,
  })  : elevenLabs = initial,
        textMode = textModeInitial,
        liveKit = liveKitInitial;

  @override
  Future<bool> getUseElevenLabs() async => elevenLabs;

  @override
  Future<void> setUseElevenLabs(bool newValue) async => elevenLabs = newValue;

  @override
  Future<bool> getUseTextMode() async => textMode;

  @override
  Future<void> setUseTextMode(bool newValue) async => textMode = newValue;

  @override
  Future<bool> getUseLiveKit() async => liveKit;

  @override
  Future<void> setUseLiveKit(bool value) async => liveKit = value;
}

/// In-memory server: applies the same rule as the agent (no voice without
/// capture) and can be made to fail.
class _FakeLifeStorySettingsRepository implements LifeStorySettingsRepository {
  _FakeLifeStorySettingsRepository([
    this.stored = const LifeStorySettings(),
  ]);

  LifeStorySettings stored;
  bool failOnFetch = false;
  bool failOnSave = false;
  final saved = <LifeStorySettings>[];

  @override
  Future<LifeStorySettings> fetch() async {
    if (failOnFetch) throw Exception('server unavailable');
    return stored;
  }

  @override
  Future<LifeStorySettings> save(LifeStorySettings settings) async {
    if (failOnSave) throw Exception('server unavailable');
    saved.add(settings);
    return stored = settings.copyWith(
      keepAudio: settings.captureEnabled && settings.keepAudio,
    );
  }
}

Widget _buildScreen({
  _FakeSettingsService? settingsService,
  AuthService? authService,
  LifeStorySettingsRepository? lifeStories,
}) {
  return MaterialApp(
    home: SettingsScreen(
      lifeStorySettingsRepository:
          lifeStories ?? _FakeLifeStorySettingsRepository(),
      settingsService: settingsService ?? _FakeSettingsService(),
      authService: authService ??
          AuthService.test(
            authStateChanges: const Stream.empty(),
          ),
    ),
  );
}

void main() {
  // ── Loading state ──────────────────────────────────────────────────────────

  testWidgets('shows loading indicator before settings load', (tester) async {
    await tester.pumpWidget(_buildScreen());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  // ── Loaded state ───────────────────────────────────────────────────────────

  testWidgets('shows the five cards with toggles after settings load', (tester) async {
    // Tall surface: the list only builds the cards near the viewport.
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Switch, skipOffstage: false), findsNWidgets(5));
    expect(find.text('Voix Haute Qualité'), findsOneWidget);
    expect(find.text('Mode Alterné (Texte)', skipOffstage: false), findsOneWidget);
    expect(find.text('Mode WebRTC (LiveKit)', skipOffstage: false), findsOneWidget);
    expect(find.text('Garder mes souvenirs', skipOffstage: false), findsOneWidget);
    expect(find.text('Conserver aussi ma voix', skipOffstage: false), findsOneWidget);
  });

  testWidgets('shows sign out button after settings load', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    expect(find.byKey(const Key('sign-out-button')), findsOneWidget);
  });

  // ── Initial value reflected ────────────────────────────────────────────────

  testWidgets('ElevenLabs toggle starts off when initial value is false',
      (tester) async {
    await tester.pumpWidget(_buildScreen(settingsService: _FakeSettingsService(initial: false)));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[0].value, isFalse);
  });

  testWidgets('ElevenLabs toggle starts on when initial value is true',
      (tester) async {
    await tester.pumpWidget(_buildScreen(settingsService: _FakeSettingsService(initial: true)));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[0].value, isTrue);
  });

  // ── ElevenLabs toggle interaction ──────────────────────────────────────────

  testWidgets('tapping ElevenLabs toggle enables it and persists the change',
      (tester) async {
    final service = _FakeSettingsService(initial: false);
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    final elevenLabsCard = find.ancestor(
      of: find.text('Voix Haute Qualité'),
      matching: find.byType(Card),
    );
    await tester.tap(find.descendant(of: elevenLabsCard, matching: find.byType(Switch)));
    await tester.pump();

    expect(service.elevenLabs, isTrue);
  });

  testWidgets('tapping ElevenLabs toggle disables it when previously enabled',
      (tester) async {
    final service = _FakeSettingsService(initial: true);
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    final elevenLabsCard = find.ancestor(
      of: find.text('Voix Haute Qualité'),
      matching: find.byType(Card),
    );
    await tester.tap(find.descendant(of: elevenLabsCard, matching: find.byType(Switch)));
    await tester.pump();

    expect(service.elevenLabs, isFalse);
  });

  testWidgets('tapping the ElevenLabs card body also toggles the setting',
      (tester) async {
    final service = _FakeSettingsService(initial: false);
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    await tester.tap(find.text('Voix Haute Qualité'));
    await tester.pump();

    expect(service.elevenLabs, isTrue);
  });

  // ── Text mode toggle ───────────────────────────────────────────────────────

  testWidgets('text mode toggle starts off by default', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[1].value, isFalse);
  });

  testWidgets('text mode toggle starts on when initial value is true',
      (tester) async {
    await tester.pumpWidget(_buildScreen(settingsService: _FakeSettingsService(textModeInitial: true)));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[1].value, isTrue);
  });

  testWidgets('tapping text mode toggle enables it and persists', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    final textModeCard = find.ancestor(
      of: find.text('Mode Alterné (Texte)', skipOffstage: false),
      matching: find.byType(Card),
    );
    await tester.ensureVisible(find.descendant(of: textModeCard, matching: find.byType(Switch), skipOffstage: false));
    await tester.tap(find.descendant(of: textModeCard, matching: find.byType(Switch), skipOffstage: false));
    await tester.pump();

    expect(service.textMode, isTrue);
  });

  // ── LiveKit toggle ─────────────────────────────────────────────────────────

  testWidgets('LiveKit toggle starts off by default', (tester) async {
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[2].value, isFalse);
  });

  testWidgets('LiveKit toggle starts on when initial value is true',
      (tester) async {
    await tester.pumpWidget(_buildScreen(settingsService: _FakeSettingsService(liveKitInitial: true)));
    await tester.pump();

    final switches = tester.widgetList<Switch>(find.byType(Switch, skipOffstage: false)).toList();
    expect(switches[2].value, isTrue);
  });

  testWidgets('tapping LiveKit toggle enables it and persists', (tester) async {
    final service = _FakeSettingsService();
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    await tester.ensureVisible(find.text('Mode WebRTC (LiveKit)', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode WebRTC (LiveKit)', skipOffstage: false));
    await tester.pump();

    expect(service.liveKit, isTrue);
  });

  testWidgets('tapping LiveKit toggle disables it when previously enabled',
      (tester) async {
    final service = _FakeSettingsService(liveKitInitial: true);
    await tester.pumpWidget(_buildScreen(settingsService: service));
    await tester.pump();

    await tester.ensureVisible(find.text('Mode WebRTC (LiveKit)', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode WebRTC (LiveKit)', skipOffstage: false));
    await tester.pump();

    expect(service.liveKit, isFalse);
  });

  // ── Life stories (consent stored on the server) ────────────────────────────

  const captureTitle = 'Garder mes souvenirs';
  const voiceTitle = 'Conserver aussi ma voix';

  Finder switchOf(String title) => find.descendant(
        of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
        matching: find.byType(Switch),
      );

  /// Tall surface so that every card is laid out and tappable.
  Future<void> pumpLoaded(
    WidgetTester tester,
    LifeStorySettingsRepository lifeStories,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen(lifeStories: lifeStories));
    await tester.pumpAndSettle();
  }

  testWidgets('life story toggles show what the server stores', (tester) async {
    await pumpLoaded(
      tester,
      _FakeLifeStorySettingsRepository(
        const LifeStorySettings(captureEnabled: true, keepAudio: true),
      ),
    );

    expect(tester.widget<Switch>(switchOf(captureTitle)).value, isTrue);
    expect(tester.widget<Switch>(switchOf(voiceTitle)).value, isTrue);
  });

  testWidgets('enabling the memories saves the consent', (tester) async {
    final repo = _FakeLifeStorySettingsRepository();
    await pumpLoaded(tester, repo);

    await tester.tap(switchOf(captureTitle));
    await tester.pumpAndSettle();

    expect(repo.saved, [const LifeStorySettings(captureEnabled: true)]);
    expect(tester.widget<Switch>(switchOf(captureTitle)).value, isTrue);
  });

  testWidgets('the voice cannot be kept while the memories are off',
      (tester) async {
    final repo = _FakeLifeStorySettingsRepository();
    await pumpLoaded(tester, repo);

    expect(tester.widget<Switch>(switchOf(voiceTitle)).onChanged, isNull);
    await tester.tap(find.text(voiceTitle));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
  });

  testWidgets('keeping the voice is saved once the memories are on',
      (tester) async {
    final repo = _FakeLifeStorySettingsRepository(
      const LifeStorySettings(captureEnabled: true),
    );
    await pumpLoaded(tester, repo);

    await tester.tap(find.text(voiceTitle));
    await tester.pumpAndSettle();

    expect(repo.saved, [
      const LifeStorySettings(captureEnabled: true, keepAudio: true),
    ]);
    expect(tester.widget<Switch>(switchOf(voiceTitle)).value, isTrue);
  });

  testWidgets('turning the memories off also stops keeping the voice',
      (tester) async {
    final repo = _FakeLifeStorySettingsRepository(
      const LifeStorySettings(captureEnabled: true, keepAudio: true),
    );
    await pumpLoaded(tester, repo);

    await tester.tap(switchOf(captureTitle));
    await tester.pumpAndSettle();

    expect(repo.saved, [const LifeStorySettings()]);
    expect(tester.widget<Switch>(switchOf(voiceTitle)).value, isFalse);
    expect(tester.widget<Switch>(switchOf(voiceTitle)).onChanged, isNull);
  });

  testWidgets('a change that cannot be saved is undone and reported',
      (tester) async {
    final repo = _FakeLifeStorySettingsRepository()..failOnSave = true;
    await pumpLoaded(tester, repo);

    await tester.tap(switchOf(captureTitle));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchOf(captureTitle)).value, isFalse);
    expect(find.text('Le réglage n\'a pas pu être enregistré.'), findsOneWidget);
  });

  testWidgets('life story toggles are disabled when the server is unreachable',
      (tester) async {
    final repo = _FakeLifeStorySettingsRepository()..failOnFetch = true;
    await pumpLoaded(tester, repo);

    expect(find.byKey(const Key('life-stories-unavailable')), findsOneWidget);
    expect(tester.widget<Switch>(switchOf(captureTitle)).onChanged, isNull);
    expect(tester.widget<Switch>(switchOf(voiceTitle)).onChanged, isNull);
    // The local settings still work.
    expect(tester.widget<Switch>(switchOf('Voix Haute Qualité')).onChanged, isNotNull);
  });

  // ── Sign out ───────────────────────────────────────────────────────────────

  testWidgets('tapping sign out shows confirmation dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();

    expect(find.text('Se déconnecter ?'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('cancelling sign out dialog does not call signOut', (tester) async {
    var signOutCalled = false;
    final auth = AuthService.test(
      signOut: () async => signOutCalled = true,
      authStateChanges: const Stream.empty(),
    );
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen(authService: auth));
    await tester.pump();

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(signOutCalled, isFalse);
    expect(find.text('Se déconnecter ?'), findsNothing);
  });

  testWidgets('confirming sign out dialog calls signOut', (tester) async {
    var signOutCalled = false;
    final auth = AuthService.test(
      signOut: () async => signOutCalled = true,
      authStateChanges: const Stream.empty(),
    );
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildScreen(authService: auth));
    await tester.pump();

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Se déconnecter'),
    ));
    await tester.pumpAndSettle();

    expect(signOutCalled, isTrue);
  });
}
