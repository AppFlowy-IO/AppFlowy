import 'package:logging/logging.dart';

enum LogLevel {
  off,
  error,
  warn,
  info,
  debug,
  all,
}

typedef LogHandler = void Function(String message);

/// Manages log service for [AppFlowyEditor]
///
/// Set the log level and config the handler depending on your need.
class LogConfiguration {
  LogConfiguration._() {
    Logger.root.onRecord.listen((record) {
      if (handler != null) {
        handler!(
          '[${record.level.toLogLevel().name}][${record.loggerName}]: ${record.time}: ${record.message}',
        );
      }
    });
  }

  factory LogConfiguration() => _logConfiguration;

  static final LogConfiguration _logConfiguration = LogConfiguration._();

  LogHandler? handler;

  LogLevel _level = LogLevel.off;

  LogLevel get level => _level;
  set level(LogLevel level) {
    _level = level;
    Logger.root.level = level.toLevel();
  }
}

/// For logging message in AppFlowyEditor
class Log {
  Log._({
    required this.name,
  }) : _logger = Logger(name);

  final String name;
  late final Logger _logger;

  /// For logging message related to [AppFlowyEditor].
  ///
  /// For example, uses the logger when registering plugins
  ///   or handling something related to [EditorState].
  static Log editor = Log._(name: 'editor');

  /// For logging message related to [AppFlowySelectionService].
  ///
  /// For example, uses the logger when updating or clearing selection.
  static Log selection = Log._(name: 'selection');

  /// For logging message related to [AppFlowyKeyboardService].
  ///
  /// For example, uses the logger when processing shortcut events.
  static Log keyboard = Log._(name: 'keyboard');

  /// For logging message related to [AppFlowyInputService].
  ///
  /// For example, uses the logger when processing text inputs.
  static Log input = Log._(name: 'input');

  /// For logging message related to [AppFlowyScrollService].
  ///
  /// For example, uses the logger when processing scroll events.
  static Log scroll = Log._(name: 'scroll');

  /// For logging message related to [AppFlowyToolbarService].
  ///
  /// For example, uses the logger when processing toolbar events.
  static Log toolbar = Log._(name: 'toolbar');

  /// For logging message related to UI.
  ///
  /// For example, uses the logger when building the widget.
  static Log ui = Log._(name: 'ui');

  void error(String message) => _logger.severe(message);
  void warn(String message) => _logger.warning(message);
  void info(String message) => _logger.info(message);
  void debug(String message) => _logger.fine(message);
}

extension on LogLevel {
  Level toLevel() {
    switch (this) {
      case LogLevel.off:
        return Level.OFF;
      case LogLevel.error:
        return Level.SEVERE;
      case LogLevel.warn:
        return Level.WARNING;
      case LogLevel.info:
        return Level.INFO;
      case LogLevel.debug:
        return Level.FINE;
      case LogLevel.all:
        return Level.ALL;
    }
  }

  String get name {
    switch (this) {
      case LogLevel.off:
        return 'OFF';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.warn:
        return 'WARN';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.all:
        return 'ALL';
    }
  }
}

extension on Level {
  LogLevel toLogLevel() {
    if (this == Level.SEVERE) {
      return LogLevel.error;
    } else if (this == Level.WARNING) {
      return LogLevel.warn;
    } else if (this == Level.INFO) {
      return LogLevel.info;
    } else if (this == Level.FINE) {
      return LogLevel.debug;
    }
    return LogLevel.off;
  }
}
