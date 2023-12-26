import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../startup.dart';

class AndroidUITask extends LaunchTask {
  const AndroidUITask();

  @override
  Future<void> initialize(LaunchContext context) async {
    if (!Platform.isAndroid) {
      return;
    }
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
