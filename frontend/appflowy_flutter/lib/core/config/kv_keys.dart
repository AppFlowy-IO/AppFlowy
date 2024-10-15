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

  /// The key for saving the window status
  ///
  /// The value is a json string with the following format:
  ///  { 'windowMaximized': true }
  ///
  static const String windowMaximized = 'windowMaximized';

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
  static const String kDocumentAppearanceWidth = 'kDocumentAppearanceWidth';

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

  /// The key for saving show notification icon option
  ///
  /// The value is a boolean string
  static const String showNotificationIcon = 'showNotificationIcon';

  /// The key for saving the last opened workspace id
  ///
  /// The workspace id is a string.
  @Deprecated('deprecated in version 0.5.5')
  static const String lastOpenedWorkspaceId = 'lastOpenedWorkspaceId';

  /// The key for saving the scale factor
  ///
  /// The value is a double string.
  static const String scaleFactor = 'scaleFactor';

  /// The key for saving the last opened tab (favorite, recent, space etc.)
  ///
  /// The value is a int string.
  static const String lastOpenedSpace = 'lastOpenedSpace';

  /// The key for saving the space tab order
  ///
  /// The value is a json string with the following format:
  /// [0, 1, 2]
  static const String spaceOrder = 'spaceOrder';

  /// The key for saving the last opened space id (space A, space B)
  ///
  /// The value is a string.
  static const String lastOpenedSpaceId = 'lastOpenedSpaceId';

  /// The key for saving the upgrade space tag
  ///
  /// The value is a boolean string
  static const String hasUpgradedSpace = 'hasUpgradedSpace060';
}
