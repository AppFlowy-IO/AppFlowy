import 'dart:io';

import 'package:appflowy_backend/log.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../startup.dart';

class ApplicationInfo {
  static int androidSDKVersion = -1;
  static String applicationVersion = '';
  static String buildNumber = '';
  static String deviceId = '';
}

class ApplicationInfoTask extends LaunchTask {
  const ApplicationInfoTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      ApplicationInfo.androidSDKVersion = androidInfo.version.sdkInt;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      ApplicationInfo.applicationVersion = packageInfo.version;
      ApplicationInfo.buildNumber = packageInfo.buildNumber;
    }

    String? deviceId;
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.device;
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      } else if (Platform.isMacOS) {
        final MacOsDeviceInfo macInfo = await deviceInfoPlugin.macOsInfo;
        deviceId = macInfo.systemGUID;
      } else if (Platform.isWindows) {
        final WindowsDeviceInfo windowsInfo =
            await deviceInfoPlugin.windowsInfo;
        deviceId = windowsInfo.deviceId;
      } else if (Platform.isLinux) {
        final LinuxDeviceInfo linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceId = linuxInfo.machineId;
      } else {
        deviceId = null;
      }
    } catch (e) {
      Log.error('Failed to get platform version, $e');
    }

    ApplicationInfo.deviceId = deviceId ?? '';
  }

  @override
  Future<void> dispose() async {}
}
