// ignore: import_of_legacy_library_into_null_safe
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'ffi.dart';

class Log {
  static final shared = Log();
  late Logger _logger;

  Log() {
    _logger = Logger(
      printer: PrettyPrinter(
          methodCount: 2, // number of method calls to be displayed
          errorMethodCount:
              8, // number of method calls if stacktrace is provided
          lineLength: 120, // width of the output
          colors: true, // Colorful log messages
          printEmojis: true, // Print an emoji for each log message
          printTime: false // Should each log print contain a timestamp
          ),
    );
  }

  static void info(dynamic msg) {
    if (isReleaseVersion()) {
      log(0, toNativeUtf8(msg));
    } else {
      Log.shared._logger.i(msg);
    }
  }

  static void debug(dynamic msg) {
    if (isReleaseVersion()) {
      log(1, toNativeUtf8(msg));
    } else {
      Log.shared._logger.d(msg);
    }
  }

  static void warn(dynamic msg) {
    if (isReleaseVersion()) {
      log(3, toNativeUtf8(msg));
    } else {
      Log.shared._logger.w(msg);
    }
  }

  static void trace(dynamic msg) {
    if (isReleaseVersion()) {
      log(2, toNativeUtf8(msg));
    } else {
      Log.shared._logger.v(msg);
    }
  }

  static void error(dynamic msg) {
    if (isReleaseVersion()) {
      log(4, toNativeUtf8(msg));
    } else {
      Log.shared._logger.e(msg);
    }
  }
}

bool isReleaseVersion() {
  return kReleaseMode;
}

Pointer<ffi.Utf8> toNativeUtf8(dynamic msg) {
  return "$msg".toNativeUtf8();
}
