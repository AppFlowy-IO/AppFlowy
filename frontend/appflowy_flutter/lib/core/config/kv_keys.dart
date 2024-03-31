class KVKeys {
  const KVKeys._();

  static const String prefix = 'io.appflowy.appflowy_flutter';

  /// The key for the path location of the local data for the whole app.
  static const String pathLocation = '$prefix.path_location';

  /// The key for saving the window size
  ///
  /// The value is a json string with the following format:
  ///   {'height': 600.0, 'width': 800.0}
  static const String windowSize = 'windowSize';

  /// The key for saving the window position
  ///
  /// The value is a json string with the following format:
  ///   {'dx': 10.0, 'dy': 10.0}
  static const String windowPosition = 'windowPosition';

  static const String kDocumentAppearanceFontSize =
      'kDocumentAppearanceFontSize';
  static const String kDocumentAppearanceFontFamily =
      'kDocumentAppearanceFontFamily';
  static const String kDocumentAppearanceDefaultTextDirection =
      'kDocumentAppearanceDefaultTextDirection';
  static const String kDocumentAppearanceCursorColor =
      'kDocumentAppearanceCursorColor';
  static const String kDocumentAppearanceSelectionColor =
      'kDocumentAppearanceSelectionColor';

  /// The key for saving the expanded views
  ///
  /// The value is a json string with the following format:
  ///  {'viewId': true, 'viewId2': false}
  static const String expandedViews = 'expandedViews';

  /// The key for saving the expanded folder
  ///
  /// The value is a json string with the following format:
  ///  {'SidebarFolderCategoryType.value': true}
  static const String expandedFolders = 'expandedFolders';

  /// The key for saving if showing the rename dialog when creating a new file
  ///
  /// The value is a boolean string.
  static const String showRenameDialogWhenCreatingNewFile =
      'showRenameDialogWhenCreatingNewFile';

  static const String kCloudType = 'kCloudType';
  static const String kAppflowyCloudBaseURL = 'kAppFlowyCloudBaseURL';
  static const String kSupabaseURL = 'kSupabaseURL';
  static const String kSupabaseAnonKey = 'kSupabaseAnonKey';

  /// The key for saving the text scale factor.
  ///
  /// The value is a double string.
  /// The value range is from 0.8 to 1.0. If it's greater than 1.0, it will cause
  ///   the text to be too large and not aligned with the icon
  static const String textScaleFactor = 'textScaleFactor';

  /// The key for saving the feature flags
  ///
  /// The value is a json string with the following format:
  /// {'feature_flag_1': true, 'feature_flag_2': false}
  static const String featureFlag = 'featureFlag';

  /// The key for saving the last opened workspace id
  ///
  /// The workspace id is a string.
  static const String lastOpenedWorkspaceId = 'lastOpenedWorkspaceId';
}
