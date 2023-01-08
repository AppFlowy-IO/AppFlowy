// ignore: import_of_legacy_library_into_null_safe
import 'package:logger/logger.dart';

class Log {
  static final shared = Log();
  late Logger _logger;

  Log() {
    _logger = Logger(
      printer: PrettyPrinter(
          methodCount: 2, // number of method calls to be displayed
          errorMethodCount: 8, // number of method calls if stacktrace is provided
          lineLength: 120, // width of the output
          colors: true, // Colorful log messages
          printEmojis: true, // Print an emoji for each log message
          printTime: false // Should each log print contain a timestamp
          ),
    );
  }

  static void info(dynamic msg) {
    Log.shared._logger.i(msg);
  }

  static void debug(dynamic msg) {
    Log.shared._logger.d(msg);
  }

  static void warn(dynamic msg) {
    Log.shared._logger.w(msg);
  }

  static void trace(dynamic msg) {
    Log.shared._logger.v(msg);
  }

  static void error(dynamic msg) {
    Log.shared._logger.e(msg);
  }
}
