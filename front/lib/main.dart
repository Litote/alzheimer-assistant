import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alzheimer_assistant/app/app.dart';
import 'package:alzheimer_assistant/core/constants/app_constants.dart';

void main() async {
  assert(
    AppConstants.elevenLabsApiKey.isNotEmpty,
    'ELEVENLABS_API_KEY doit être fourni via --dart-define=ELEVENLABS_API_KEY=...',
  );
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const App());
}
