import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../startup.dart';

bool _enable = true;
const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

class MemoryLeakDetectorTask extends LaunchTask {
  MemoryLeakDetectorTask();

  Timer? _timer;

  @override
  Future<void> initialize(LaunchContext context) async {
    if (!kDebugMode || !_enable) {
      return;
    }
    LeakTracking.start();
    LeakTracking.phase = const PhaseSettings(
      leakDiagnosticConfig: LeakDiagnosticConfig(
        collectRetainingPathForNotGCed: true,
      ),
    );
    MemoryAllocations.instance.addListener((p0) {
      LeakTracking.dispatchObjectEvent(p0.toMap());
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final summary = await LeakTracking.checkLeaks();
      if (summary.isEmpty) {
        return;
      }
      final details = await LeakTracking.collectLeaks();
      final notDisposed = details.notDisposed;
      final blackTrackedClassList = ['package:flutter/widgets.dart/Element'];
      for (final value in notDisposed) {
        if (blackTrackedClassList.contains(value.trackedClass)) {
          continue;
        }
        debugPrint(_encoder.convert(value.toJson()));
      }
    });
  }

  @override
  Future<void> dispose() async {
    if (!kDebugMode || !_enable) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    LeakTracking.stop();
  }
}
