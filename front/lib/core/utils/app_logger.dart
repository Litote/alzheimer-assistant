import 'package:logger/logger.dart';

/// Shared logger instance for the whole app.
///
/// Uses [DateTimeFormat.onlyTimeAndSinceStart] to show:
///   - the wall-clock time of each log entry
///   - the elapsed time since the app started
///
/// This makes it easy to measure latency between events (e.g. mic start →
/// first audio chunk → turn complete → playback done).
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
