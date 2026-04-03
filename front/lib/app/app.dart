import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/app/router.dart';
import 'package:alzheimer_assistant/app/theme.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/live_repository_impl.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/shared/services/buffered_audio_player_service.dart';
import 'package:alzheimer_assistant/shared/services/microphone_stream_service.dart';
import 'package:alzheimer_assistant/shared/services/pcm_streaming_audio_player_service.dart';
import 'package:alzheimer_assistant/shared/services/settings_service.dart';
import 'package:alzheimer_assistant/shared/services/streaming_audio_player_service.dart';

// Select audio player implementation at build time:
//   --dart-define=AUDIO_PLAYER_MODE=pcm      (default) real-time PCM, hardware AEC
//   --dart-define=AUDIO_PLAYER_MODE=buffered  WAV buffer, more compatible
const _audioPlayerMode = String.fromEnvironment(
  'AUDIO_PLAYER_MODE',
  defaultValue: 'pcm',
);

// Enable transcription display at build time:
//   --dart-define=SHOW_TRANSCRIPTION=true   show input/output transcriptions in UI
//   (default: false — no text displayed)
const _showTranscription = bool.fromEnvironment('SHOW_TRANSCRIPTION');

StreamingAudioPlayerService _createAudioPlayer() =>
    _audioPlayerMode == 'buffered'
        ? BufferedAudioPlayerService()
        : PcmStreamingAudioPlayerService();

class App extends StatelessWidget {
  const App({super.key}) : _testBloc = null;

  // Constructor reserved for E2E tests: injects a pre-configured bloc
  // with mocked services, without touching production code.
  // ignore: prefer_const_constructors_in_immutables
  App.forTesting({super.key, required AssistantBloc bloc})
      : _testBloc = bloc;

  final AssistantBloc? _testBloc;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => SettingsService(),
      child: Builder(
        builder: (context) => BlocProvider(
          create: (_) =>
              _testBloc ??
              AssistantBloc(
                liveRepository: LiveRepositoryImpl(),
                micService: MicrophoneStreamService(),
                audioPlayer: _createAudioPlayer(),
                showTranscription: _showTranscription,
                settingsService: context.read<SettingsService>(),
              ),
          child: MaterialApp.router(
            title: 'Assistant',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: appRouter,
          ),
        ),
      ),
    );
  }
}
