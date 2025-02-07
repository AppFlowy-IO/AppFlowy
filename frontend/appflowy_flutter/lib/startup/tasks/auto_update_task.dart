import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/version_checker/version_checker.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import '../startup.dart';

class AutoUpdateTask extends LaunchTask {
  AutoUpdateTask();

  static const _feedUrl =
      'https://github.com/LucasXu0/AppFlowy/releases/latest/download/appcast-{os}-{arch}.xml';
  final _listener = _AppFlowyAutoUpdaterListener();

  final _versionChecker = VersionChecker();

  @override
  Future<void> initialize(LaunchContext context) async {
    // the auto updater is not supported on mobile and linux
    if (UniversalPlatform.isMobile) {
      return;
    }

    _setupAutoUpdater();

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

  // On macOS and windows, we use auto_updater to check for updates.
  // On linux, we use the version checker to check for updates because the auto_updater is not supported.
  Future<void> _setupAutoUpdater() async {
    Log.info(
      '[AutoUpdate] current version: ${ApplicationInfo.applicationVersion}, current cpu architecture: ${ApplicationInfo.architecture}',
    );

    if (UniversalPlatform.isMacOS || UniversalPlatform.isWindows) {
      autoUpdater.addListener(_listener);

      // Since the appcast.xml is not supported the arch, we separate the feed url by os and arch.
      final feedUrl = _feedUrl
          .replaceAll('{os}', ApplicationInfo.os)
          .replaceAll('{arch}', ApplicationInfo.architecture);
      Log.info('[AutoUpdate] feed url: $feedUrl');

      await autoUpdater.setFeedURL(feedUrl);
      await autoUpdater.checkForUpdateInformation();
    } else if (UniversalPlatform.isLinux) {
      _versionChecker.setFeedUrl(_feedUrl);
      final item = await _versionChecker.checkForUpdate();
      if (item != null) {
        ApplicationInfo.latestAppcastItem = item;
        ApplicationInfo.latestVersionNotifier.value =
            item.displayVersionString ?? '';
      }
    } else {
      Log.error('[AutoUpdate] Auto updater is not supported on this platform');
    }
  }

  void _showCriticalUpdateDialog() {
    showCustomConfirmDialog(
      context: AppGlobals.rootNavKey.currentContext!,
      title: LocaleKeys.autoUpdate_criticalUpdateTitle.tr(),
      description: LocaleKeys.autoUpdate_criticalUpdateDescription.tr(
        namedArgs: {
          'currentVersion': ApplicationInfo.applicationVersion,
          'newVersion': ApplicationInfo.latestVersion,
        },
      ),
      builder: (context) => const SizedBox.shrink(),
      // if the update is critical, dont allow the user to dismiss the dialog
      barrierDismissible: false,
      showCloseButton: false,
      enableKeyboardListener: false,
      closeOnConfirm: false,
      confirmLabel: LocaleKeys.autoUpdate_criticalUpdateButton.tr(),
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
  void onUpdaterUpdateCancelled(AppcastItem? item) {
    _updateVersionNotifier(item);

    Log.info('[AutoUpdate] Update cancelled: ${item?.displayVersionString}');
  }

  @override
  void onUpdaterUpdateInstalled(AppcastItem? item) {
    _updateVersionNotifier(item);

    Log.info('[AutoUpdate] Update installed: ${item?.displayVersionString}');
  }

  @override
  void onUpdaterUpdateSkipped(AppcastItem? item) {
    _updateVersionNotifier(item);

    Log.info('[AutoUpdate] Update skipped: ${item?.displayVersionString}');
  }

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
