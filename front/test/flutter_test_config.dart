import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global configuration for Flutter tests.
/// This file is automatically executed by the Flutter test framework.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Capture the default comparator to preserve its base directory logic.
  final defaultComparator = goldenFileComparator;
  
  if (defaultComparator is LocalFileComparator) {
    // We wrap the comparator to allow a small pixel difference (0.5%) 
    // to account for subpixel rendering variations between different 
    // ARM64 environments (e.g., Local M4 vs CI M1/M2).
    // We use resolve('config.dart') to ensure the basedir remains the same 
    // as the original one (LocalFileComparator uses the parent dir of the URI).
    goldenFileComparator = _TolerantGoldenFileComparator(
      defaultComparator.basedir.resolve('flutter_test_config.dart'),
      tolerance: 0.005,
    );
  }

  await testMain();
}

/// A [LocalFileComparator] that allows a specific [tolerance] in pixel differences.
class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(super.testFile, {required this.tolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= tolerance) {
      return true;
    }

    final String error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
