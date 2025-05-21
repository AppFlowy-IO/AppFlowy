// ignore: import_of_legacy_library_into_null_safe
import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';

import 'ffi.dart';

class Log {
  static final shared = Log();

  late Talker _logger;

  bool enableFlutterLog = true;

  // used to disable log in tests
  bool disableLog = false;

  Log() {
    _logger = Talker(
      filter: LogLevelTalkerFilter(),
    );
  }

  // Generic internal logging function to reduce code duplication
  static void _log(
    LogLevel level,
    int rustLevel,
    dynamic msg, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    // only forward logs to flutter in debug mode, otherwise log to rust to
    // persist logs in the file system
    if (shared.enableFlutterLog && kDebugMode) {
      shared._logger.log(msg, logLevel: level, stackTrace: stackTrace);
    } else {
      String formattedMessage = _formatMessageWithStackTrace(msg, stackTrace);
      rust_log(rustLevel, toNativeUtf8(formattedMessage));
    }
  }

  static void info(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    if (shared.disableLog) {
      return;
    }

    _log(LogLevel.info, 0, msg, error, stackTrace);
  }

  static void debug(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    if (shared.disableLog) {
      return;
    }

    _log(LogLevel.debug, 1, msg, error, stackTrace);
  }

  static void warn(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    if (shared.disableLog) {
      return;
    }

    _log(LogLevel.warning, 3, msg, error, stackTrace);
  }

  static void trace(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    if (shared.disableLog) {
      return;
    }

    _log(LogLevel.verbose, 2, msg, error, stackTrace);
  }

  static void error(dynamic msg, [dynamic error, StackTrace? stackTrace]) {
    if (shared.disableLog) {
      return;
    }

    _log(LogLevel.error, 4, msg, error, stackTrace);
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

class LogLevelTalkerFilter implements TalkerFilter {
  @override
  bool filter(TalkerData data) {
    // filter out the debug logs in release mode
    return kDebugMode ? true : data.logLevel != LogLevel.debug;
  }
}
