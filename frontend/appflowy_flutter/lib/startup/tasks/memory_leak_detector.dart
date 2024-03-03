import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../startup.dart';

bool enableMemoryLeakDetect = false;
bool dumpMemoryLeakPerSecond = false;

void dumpMemoryLeak({
  LeakType type = LeakType.notDisposed,
}) async {
  final details = await LeakTracking.collectLeaks();
  details.dumpDetails(type);
}

class MemoryLeakDetectorTask extends LaunchTask {
  MemoryLeakDetectorTask();

  Timer? _timer;

  @override
  Future<void> initialize(LaunchContext context) async {
    if (!kDebugMode || !enableMemoryLeakDetect) {
      return;
    }

    LeakTracking.start();
    LeakTracking.phase = const PhaseSettings(
      leakDiagnosticConfig: LeakDiagnosticConfig(
        collectRetainingPathForNotGCed: true,
        collectStackTraceOnStart: true,
      ),
    );

    FlutterMemoryAllocations.instance.addListener((p0) {
      LeakTracking.dispatchObjectEvent(p0.toMap());
    });

    // dump memory leak per second if needed
    if (dumpMemoryLeakPerSecond) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final summary = await LeakTracking.checkLeaks();
        if (summary.isEmpty) {
          return;
        }

        dumpMemoryLeak();
      });
    }
  }

  @override
  Future<void> dispose() async {
    if (!kDebugMode || !enableMemoryLeakDetect) {
      return;
    }

    if (dumpMemoryLeakPerSecond) {
      _timer?.cancel();
      _timer = null;
    }

    LeakTracking.stop();
  }
}

extension on LeakType {
  String get desc => switch (this) {
        LeakType.notDisposed => 'not disposed',
        LeakType.notGCed => 'not GCed',
        LeakType.gcedLate => 'GCed late'
      };
}

final _dumpablePackages = [
  'package:appflowy/',
  'package:appflowy_editor/',
];

extension on Leaks {
  void dumpDetails(LeakType type) {
    final summary = '${type.desc}: ${switch (type) {
      LeakType.notDisposed => '${notDisposed.length}',
      LeakType.notGCed => '${notGCed.length}',
      LeakType.gcedLate => '${gcedLate.length}'
    }}';
    debugPrint(summary);
    final details = switch (type) {
      LeakType.notDisposed => notDisposed,
      LeakType.notGCed => notGCed,
      LeakType.gcedLate => gcedLate
    };

    // only dump the code in appflowy
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
