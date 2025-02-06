import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import '../startup.dart';

class AutoUpdateTask extends LaunchTask {
  AutoUpdateTask();

  static const _feedUrl =
      'https://github.com/LucasXu0/AppFlowy/releases/latest/download/appcast-{os}-{arch}.xml';
  final _listener = _AppFlowyAutoUpdaterListener();

  @override
  Future<void> initialize(LaunchContext context) async {
    // the auto updater is not supported on mobile
    if (UniversalPlatform.isMobile) {
      return;
    }

    Log.info(
      '[AutoUpdate] current version: ${ApplicationInfo.applicationVersion}, current cpu architecture: ${ApplicationInfo.architecture}',
    );

    autoUpdater.addListener(_listener);

    // Since the appcast.xml is not supported the arch, we separate the feed url by os and arch.
    final feedUrl = _feedUrl
        .replaceAll('{os}', ApplicationInfo.os)
        .replaceAll('{arch}', ApplicationInfo.architecture);
    Log.info('[AutoUpdate] feed url: $feedUrl');
    await autoUpdater.setFeedURL(feedUrl);
    await autoUpdater.checkForUpdateInformation();

    ApplicationInfo.isCriticalUpdateNotifier.addListener(
      _showCriticalUpdateDialog,
    );
  }

  @override
  Future<void> dispose() async {
    autoUpdater.removeListener(_listener);

    ApplicationInfo.isCriticalUpdateNotifier.removeListener(
      _showCriticalUpdateDialog,
    );
  }

  void _showCriticalUpdateDialog() {
    showCustomConfirmDialog(
      context: AppGlobals.rootNavKey.currentContext!,
      title: 'Critical update',
      description:
          'A critical update is available. Please update to the latest version.',
      builder: (context) => const SizedBox.shrink(),
      // if the update is critical, dont allow the user to dismiss the dialog
      barrierDismissible: false,
      showCloseButton: false,
      enableKeyboardListener: false,
      closeOnConfirm: false,
      confirmLabel: 'Update now',
      onConfirm: () async {
        await autoUpdater.checkForUpdates();
      },
    );
  }
}

class _AppFlowyAutoUpdaterListener extends UpdaterListener {
  @override
  void onUpdaterBeforeQuitForUpdate(AppcastItem? item) {}

  @override
  void onUpdaterCheckingForUpdate(Appcast? appcast) {
    // Due to the reason documented in the following link, the update will not be found if the user has skipped the update.
    // We have to check the skipped version manually.
    // https://sparkle-project.org/documentation/api-reference/Classes/SPUUpdater.html#/c:objc(cs)SPUUpdater(im)checkForUpdateInformation
    final items = appcast?.items;
    if (items != null) {
      final String? currentPlatform;
      if (UniversalPlatform.isMacOS) {
        currentPlatform = 'macos';
      } else if (UniversalPlatform.isWindows) {
        currentPlatform = 'windows';
      } else {
        currentPlatform = null;
      }

      final matchingItem = items.firstWhereOrNull(
        (item) => item.os == currentPlatform,
      );

      if (matchingItem != null) {
        _updateVersionNotifier(matchingItem);

        Log.info(
          '[AutoUpdate] latest version: ${matchingItem.displayVersionString}',
        );
      }
    }
  }

  @override
  void onUpdaterError(UpdaterError? error) {
    Log.error('[AutoUpdate] On update error: $error');
  }

  @override
  void onUpdaterUpdateNotAvailable(UpdaterError? error) {
    Log.info('[AutoUpdate] Update not available $error');
  }

  @override
  void onUpdaterUpdateAvailable(AppcastItem? item) {
    _updateVersionNotifier(item);

    Log.info('[AutoUpdate] Update available: ${item?.displayVersionString}');
  }

  @override
  void onUpdaterUpdateDownloaded(AppcastItem? item) {
    Log.info('[AutoUpdate] Update downloaded: ${item?.displayVersionString}');
  }

  @override
  void onUpdaterUserUpdateChoice(
    UserUpdateChoice? choice,
    AppcastItem? appcastItem,
  ) {
    _updateVersionNotifier(appcastItem);
    Log.info('[AutoUpdate] User update choice: $choice');
  }

  // call this function when getting the latest appcast item
  void _updateVersionNotifier(AppcastItem? item) {
    if (item != null) {
      ApplicationInfo.latestAppcastItem = item;
      ApplicationInfo.latestVersionNotifier.value =
          item.displayVersionString ?? '';
    }
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
