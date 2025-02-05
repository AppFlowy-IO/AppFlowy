import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

import '../startup.dart';

class AutoUpdateTask extends LaunchTask {
  AutoUpdateTask();

  static const _feedUrl =
      'https://github.com/LucasXu0/AppFlowy/releases/latest/download/appcast.xml';
  final _listener = _AppFlowyAutoUpdaterListener();

  @override
  Future<void> initialize(LaunchContext context) async {
    // the auto updater is not supported on mobile
    if (UniversalPlatform.isMobile) {
      return;
    }

    autoUpdater.addListener(_listener);
    await autoUpdater.setFeedURL(_feedUrl);
    await autoUpdater.checkForUpdateInformation();
    await autoUpdater.checkForUpdates();
  }

  @override
  Future<void> dispose() async {
    autoUpdater.removeListener(_listener);
  }
}

class _AppFlowyAutoUpdaterListener extends UpdaterListener {
  @override
  void onUpdaterBeforeQuitForUpdate(AppcastItem? item) {
    debugPrint('[Updater] Before quit for update ${item?.toJson()}');
  }

  @override
  void onUpdaterCheckingForUpdate(Appcast? appcast) {
    debugPrint('[Updater] Checking for update ${appcast?.toJson()}');
  }

  @override
  void onUpdaterError(UpdaterError? error) {
    debugPrint('[Updater] Error: $error');
  }

  @override
  void onUpdaterUpdateNotAvailable(UpdaterError? error) {
    debugPrint('[Updater] Update not available $error');
  }

  @override
  void onUpdaterUpdateAvailable(AppcastItem? item) {
    debugPrint('[Updater] Update available: ${item?.toJson()}');
    ApplicationInfo.latestVersionNotifier.value =
        item?.displayVersionString ?? '';
  }

  @override
  void onUpdaterUpdateDownloaded(AppcastItem? item) {
    debugPrint('[Updater] Update downloaded: ${item?.toJson()}');
  }

  @override
  void onUpdaterUserUpdateChoice(
    UserUpdateChoice? choice,
    AppcastItem? appcastItem,
  ) {
    if (choice == UserUpdateChoice.skip) {
      // save the skipped version
      final latestVersion = appcastItem?.displayVersionString;
      if (latestVersion != null) {
        getIt<KeyValueStorage>().set(KVKeys.skippedVersion, latestVersion);
      }
    }
    debugPrint('[Updater] User update choice: $choice');
  }
}

class AppFlowyAutoUpdateVersion {
  AppFlowyAutoUpdateVersion({
    required this.latestVersion,
    required this.currentVersion,
    required this.isForceUpdate,
  });

  factory AppFlowyAutoUpdateVersion.initial() => AppFlowyAutoUpdateVersion(
        latestVersion: '0.0.0',
        currentVersion: '0.0.0',
        isForceUpdate: false,
      );

  final String latestVersion;
  final String currentVersion;

  final bool isForceUpdate;

  bool get isUpdateAvailable => latestVersion != currentVersion;
}
