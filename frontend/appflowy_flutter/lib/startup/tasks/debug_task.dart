import 'package:appflowy/startup/startup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:universal_platform/universal_platform.dart';

class DebugTask extends LaunchTask {
  DebugTask();

  final Talker talker = Talker();

  @override
  Future<void> initialize(LaunchContext context) async {
    // hide the keyboard on mobile
    if (UniversalPlatform.isMobile && kDebugMode) {
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    }

    // log the bloc events
    if (kDebugMode) {
      Bloc.observer = TalkerBlocObserver(
        talker: talker,
        settings: TalkerBlocLoggerSettings(
          // enable it if you want to observer all the bloc events
          enabled: false,
          printEventFullData: false,
          printStateFullData: false,
          printChanges: true,
          printClosings: true,
          printCreations: true,
          transitionFilter: (_, transition) {
            // do the filter here if you need to observer a specific bloc
            return true;
          },
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
