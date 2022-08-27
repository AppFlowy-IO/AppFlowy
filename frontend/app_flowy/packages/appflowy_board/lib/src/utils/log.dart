import 'package:flutter/material.dart';

// ignore: constant_identifier_names
const DART_LOG = "Dart_LOG";

class Log {
  static const enableLog = false;

  static void info(String? message) {
    if (enableLog) {
      debugPrint('ℹ️[Info]=> $message');
    }
  }

  static void debug(String? message) {
    if (enableLog) {
      debugPrint('🐛[Debug] - ${DateTime.now().second}=> $message');
    }
  }

  static void warn(String? message) {
    if (enableLog) {
      debugPrint('🐛[Warn] - ${DateTime.now().second} => $message');
    }
  }

  static void trace(String? message) {
    if (enableLog) {
      debugPrint('❗️[Trace] - ${DateTime.now().second}=> $message');
    }
  }
}
