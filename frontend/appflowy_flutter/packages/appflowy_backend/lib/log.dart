// ignore: import_of_legacy_library_into_null_safe
import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'ffi.dart';

class Log {
  static final shared = Log();
  late Logger _logger;

  Log() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
      ),
      level: kDebugMode ? Level.trace : Level.info,
    );
  }

  // Generic internal logging function to reduce code duplication
  static void _log(Level level, int rustLevel, dynamic msg,
      [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      switch (level) {
        case Level.info:
          shared._logger.i(msg, stackTrace: stackTrace);
          break;
        case Level.debug:
          shared._logger.d(msg, stackTrace: stackTrace);
          break;
        case Level.warning:
          shared._logger.w(msg, stackTrace: stackTrace);
          break;
        case Level.error:
          shared._logger.e(msg, stackTrace: stackTrace);
          break;
        case Level.trace:
          shared._logger.t(msg, stackTrace: stackTrace);
          break;
        default:
          shared._logger.log(level, msg, stackTrace: stackTrace);
      }
    }
    String formattedMessage = _formatMessageWithStackTrace(msg, stackTrace);
    rust_log(rustLevel, toNativeUtf8(formattedMessage));
  }

  static void info(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.info, 0, msg, error, stackTrace);
  }

  static void debug(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.debug, 1, msg, error, stackTrace);
  }

  static void warn(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.warning, 3, msg, error, stackTrace);
  }

  static void trace(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.trace, 2, msg, error, stackTrace);
  }

  static void error(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.error, 4, msg, error, stackTrace);
  }
}

bool isReleaseVersion() {
  return kReleaseMode;
}

// Utility to convert a message to native Utf8 (used in rust_log)
Pointer<ffi.Utf8> toNativeUtf8(dynamic msg) {
  return "$msg".toNativeUtf8();
}

String _formatMessageWithStackTrace(dynamic msg, StackTrace? stackTrace) {
   if (stackTrace != null) {
     return "$msg\nStackTrace:\n$stackTrace"; // Append the stack trace to the message
   }
   return msg.toString();
 }
