import 'dart:io';
import 'package:app_flowy/startup/launch.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:bloc/bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flowy_sdk/flowy_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/flowy_logger.dart';

class RustSDKInitTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    WidgetsFlutterBinding.ensureInitialized();

    Bloc.observer = ApplicationBlocObserver();

    Directory directory = await getApplicationDocumentsDirectory();
    final documentPath = directory.path;
    final flowySandbox = Directory('$documentPath/flowy');
    switch (context.env) {
      case IntegrationEnv.dev:
        // await context.getIt<FlowySDK>().init(Directory('./temp/flowy_dev'));
        await context.getIt<FlowySDK>().init(flowySandbox);
        break;
      case IntegrationEnv.pro:
        await context.getIt<FlowySDK>().init(flowySandbox);
        break;
      default:
        assert(false, 'Unsupported env');
    }

    return Future(() => {});
  }
}

class ApplicationBlocObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    Log.debug(transition);
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    Log.debug(error);
    super.onError(bloc, error, stackTrace);
  }
}

class EngineBlocConfig {
  static void setup() {
    Bloc.observer = ApplicationBlocObserver();
  }
}
