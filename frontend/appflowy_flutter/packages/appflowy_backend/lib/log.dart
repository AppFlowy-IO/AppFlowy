// ignore: import_of_legacy_library_into_null_safe
import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'ffi.dart';

class Log {
  static final shared = Log();
  // ignore: unused_field
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
          dateTimeFormat:
              DateTimeFormat.none // Should each log print contain a timestamp
          ),
      level: kDebugMode ? Level.trace : Level.info,
    );
  }

  static void info(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    rust_log(0, toNativeUtf8(msg));
  }

  static void debug(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    rust_log(1, toNativeUtf8(msg));
  }

  static void warn(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    rust_log(3, toNativeUtf8(msg));
  }

  static void trace(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    rust_log(2, toNativeUtf8(msg));
  }

  static void error(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    rust_log(4, toNativeUtf8(msg));
  }
}

bool isReleaseVersion() {
  return kReleaseMode;
}

Pointer<ffi.Utf8> toNativeUtf8(dynamic msg) {
  return "$msg".toNativeUtf8();
}
