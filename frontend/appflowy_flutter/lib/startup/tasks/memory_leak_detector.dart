import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../startup.dart';

bool _enable = false;

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
        collectStackTraceOnStart: true,
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
      dumpDetails(LeakType.notDisposed, details);
      // dumpDetails(LeakType.notGCed, details);
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

  final _dumpablePackages = [
    'package:appflowy/',
  ];
  void dumpDetails(LeakType type, Leaks leaks) {
    final summary = '${type.desc}: ${switch (type) {
      LeakType.notDisposed => '${leaks.notDisposed.length}',
      LeakType.notGCed => '${leaks.notGCed.length}',
      LeakType.gcedLate => '${leaks.gcedLate.length}'
    }}';
    debugPrint(summary);
    final details = switch (type) {
      LeakType.notDisposed => leaks.notDisposed,
      LeakType.notGCed => leaks.notGCed,
      LeakType.gcedLate => leaks.gcedLate
    };
    for (final value in details) {
      final stack = value.context![ContextKeys.startCallstack]! as StackTrace;
      final stackInAppFlowy = stack
          .toString()
          .split('\n')
          .where(
            (stack) =>
                // ignore current file call stack
                !stack.contains('memory_leak_detector') &&
                _dumpablePackages.any((pkg) => stack.contains(pkg)),
          )
          .join('\n');
      // ignore the untreatable leak
      if (stackInAppFlowy.isEmpty) {
        continue;
      }
      final object = value.type;
      debugPrint('''
$object ${type.desc}
$stackInAppFlowy
''');
    }
  }
}

extension on LeakType {
  String get desc => switch (this) {
        LeakType.notDisposed => 'not disposed',
        LeakType.notGCed => 'not GCed',
        LeakType.gcedLate => 'GCed late'
      };
}
