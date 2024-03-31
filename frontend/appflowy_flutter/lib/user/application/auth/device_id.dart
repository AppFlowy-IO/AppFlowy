import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

Future<String> getDeviceId() async {
  if (integrationMode().isTest) {
    return "test_device_id";
  }

  String? deviceId;
  try {
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.device;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    } else if (Platform.isMacOS) {
      final MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      deviceId = macInfo.systemGUID;
    } else if (Platform.isWindows) {
      final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      deviceId = windowsInfo.deviceId;
    } else if (Platform.isLinux) {
      final LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      deviceId = linuxInfo.machineId;
    }
  } on PlatformException {
    Log.error('Failed to get platform version');
  }
  return deviceId ?? '';
}
