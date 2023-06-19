class KVKeys {
  const KVKeys._();

  static const String prefix = 'io.appflowy.appflowy_flutter';

  /// The key for the path location of the local data for the whole app.
  static const String pathLocation = '$prefix.path_location';

  /// The key for the last time login type.
  ///
  /// The value is one of the following:
  /// - local
  /// - supabase
  static const String loginType = '$prefix.login_type';

  /// The key for saving the window size
  ///
  /// The value is a json string with the following format:
  ///   {'height': 600.0, 'width': 800.0}
  static const String windowSize = 'windowSize';
}
