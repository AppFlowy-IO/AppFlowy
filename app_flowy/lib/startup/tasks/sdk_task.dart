import 'dart:io';
import 'package:app_flowy/startup/launch.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:bloc/bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flowy_sdk/flowy_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flowy_log/flowy_log.dart';

class RustSDKInitTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  @override
  Future<void> initialize(LaunchContext context) async {
    WidgetsFlutterBinding.ensureInitialized();

    Bloc.observer = ApplicationBlocObserver();

    Directory directory = await getApplicationDocumentsDirectory();
    final documentPath = directory.path;

    return Directory('$documentPath/flowy')
        .create()
        .then((Directory directory) async {
      switch (context.env) {
        case IntegrationEnv.dev:
          // await context.getIt<FlowySDK>().init(Directory('./temp/flowy_dev'));
          await context.getIt<FlowySDK>().init(directory);
          break;
        case IntegrationEnv.pro:
          await context.getIt<FlowySDK>().init(directory);
          break;
        default:
          assert(false, 'Unsupported env');
      }
    });
  }
}

class ApplicationBlocObserver extends BlocObserver {
  @override
  // ignore: unnecessary_overrides
  void onTransition(Bloc bloc, Transition transition) {
    Log.debug(
        "[current]: ${transition.currentState} \n[next]: ${transition.nextState}");
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    Log.debug(error);
    super.onError(bloc, error, stackTrace);
  }
}
