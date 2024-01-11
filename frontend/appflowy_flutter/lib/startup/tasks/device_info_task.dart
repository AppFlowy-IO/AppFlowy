import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../startup.dart';

class DeviceOrApplicationInfoTask extends LaunchTask {
  const DeviceOrApplicationInfoTask();

  static int androidSDKVersion = -1;
  static String applicationVersion = '';
  static String buildNumber = '';

  @override
  Future<void> initialize(LaunchContext context) async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      androidSDKVersion = androidInfo.version.sdkInt;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      applicationVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    }
  }

  @override
  Future<void> dispose() async {}
}
