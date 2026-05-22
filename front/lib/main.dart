import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alzheimer_assistant/app/app.dart';
import 'package:alzheimer_assistant/core/constants/app_constants.dart';

void main() async {
  assert(
    AppConstants.elevenLabsApiKey.isNotEmpty,
    'ELEVENLABS_API_KEY doit être fourni via --dart-define=ELEVENLABS_API_KEY=...',
  );
  assert(
    AppConstants.supabaseUrl.isNotEmpty,
    'SUPABASE_URL doit être fourni via --dart-define=SUPABASE_URL=...',
  );
  assert(
    AppConstants.supabaseAnonKey.isNotEmpty,
    'SUPABASE_ANON_KEY doit être fourni via --dart-define=SUPABASE_ANON_KEY=...',
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(App());
}
