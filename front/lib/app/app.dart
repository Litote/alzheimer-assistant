import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzheimer_assistant/app/router.dart';
import 'package:alzheimer_assistant/app/theme.dart';
import 'package:alzheimer_assistant/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:alzheimer_assistant/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:alzheimer_assistant/shared/services/speech_recognition_service.dart';
import 'package:alzheimer_assistant/shared/services/tts_service.dart';

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
    return BlocProvider(
      create: (_) =>
          _testBloc ??
          AssistantBloc(
            repository: AssistantRepositoryImpl(),
            speechService: SpeechRecognitionService(),
            ttsService: TtsService(),
          ),
      child: MaterialApp.router(
        title: 'Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
