import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alzheimer_assistant/app/router.dart';
import 'package:alzheimer_assistant/app/theme.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/livekit_audio_repository.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/sse_text_repository.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/ws_audio_repository.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/shared/services/auth_service.dart';
import 'package:alzheimer_assistant/shared/services/elevenlabs_client_tts_service.dart';
import 'package:alzheimer_assistant/shared/services/microphone_stream_service.dart';
import 'package:alzheimer_assistant/shared/services/native_client_tts_service.dart';
import 'package:alzheimer_assistant/shared/services/permission_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';
import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';

// Enable transcription display at build time:
//   --dart-define=SHOW_TRANSCRIPTION=true
const _showTranscription = bool.fromEnvironment('SHOW_TRANSCRIPTION');

class App extends StatelessWidget {
  App({
    Key? key,
    AuthService? authService,
    SettingsService? settingsService,
    PermissionService? permissionService,
  }) : this._(
          key: key,
          authService: authService ?? AuthService(),
          settingsService: settingsService ?? SettingsService(),
          permissionService: permissionService ?? PermissionService(),
        );

  // Constructor reserved for E2E tests: injects a pre-configured bloc
  // with mocked services, without touching production code.
  App.forTesting({
    Key? key,
    required AssistantBloc bloc,
    AuthService? authService,
    SettingsService? settingsService,
    PermissionService? permissionService,
  }) : this._(
          key: key,
          authService: authService ?? AuthService.test(),
          settingsService: settingsService ?? SettingsService(),
          permissionService: permissionService ?? PermissionService(),
          testBloc: bloc,
        );

  App._({
    required AuthService authService,
    required SettingsService settingsService,
    required PermissionService permissionService,
    AssistantBloc? testBloc,
    super.key,
  })  : _authService = authService,
        _settingsService = settingsService,
        _router = createAppRouter(
          authService: authService,
          permissionService: permissionService,
        ),
        _testBloc = testBloc;

  final AuthService _authService;
  final SettingsService _settingsService;
  final GoRouter _router;
  final AssistantBloc? _testBloc;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SettingsService>.value(value: _settingsService),
        RepositoryProvider<AuthService>.value(value: _authService),
      ],
      child: Builder(
        builder: (context) => BlocProvider(
          create: (_) =>
              _testBloc ??
              AssistantBloc(
                textRepository: SseTextRepository(),
                audioRepository: WsAudioRepository(),
                webRtcRepository: LiveKitAudioRepository(),
                micService: MicrophoneStreamService(),
                // audioPlayer is intentionally omitted here: PcmStreamingAudioPlayerService
                // is created lazily inside the BLoC on the first audio-mode connect,
                // so the iOS audio session is never touched in text mode.
                showTranscription: _showTranscription,
                settingsService: context.read<SettingsService>(),
                speechService: SpeechRecognitionService(),
                elevenLabsTtsService: ElevenLabsClientTtsService(),
                nativeTtsService: NativeClientTtsService(),
                authService: context.read<AuthService>(),
              ),
          child: MaterialApp.router(
            title: 'Assistant',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
