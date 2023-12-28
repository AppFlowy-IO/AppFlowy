import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../startup.dart';

class DeviceInfoTask extends LaunchTask {
  const DeviceInfoTask();

  static int androidSDKVersion = -1;

  @override
  Future<void> initialize(LaunchContext context) async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      androidSDKVersion = androidInfo.version.sdkInt;
    }
  }

  @override
  Future<void> dispose() async {}
}
