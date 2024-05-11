// Check if the user has the required permission to access the device's
//  - camera
//  - storage
//  - ...
import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_confirm_dialog.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionChecker {
  static Future<bool> checkPhotoPermission(BuildContext context) async {
    // check the permission first
    final status = await Permission.photos.status;
    // if the permission is permanently denied, we should open the app settings
    if (status.isPermanentlyDenied && context.mounted) {
      unawaited(
        showFlowyMobileConfirmDialog(
          context,
          title: FlowyText.semibold(
            LocaleKeys.pageStyle_photoPermissionTitle.tr(),
            maxLines: 3,
            textAlign: TextAlign.center,
          ),
          content: FlowyText(
            LocaleKeys.pageStyle_photoPermissionDescription.tr(),
            maxLines: 5,
            textAlign: TextAlign.center,
            fontSize: 12.0,
          ),
          actionAlignment: ConfirmDialogActionAlignment.vertical,
          actionButtonTitle: LocaleKeys.pageStyle_openSettings.tr(),
          actionButtonColor: Colors.blue,
          cancelButtonTitle: LocaleKeys.pageStyle_doNotAllow.tr(),
          cancelButtonColor: Colors.blue,
          onActionButtonPressed: () {
            openAppSettings();
          },
        ),
      );

      return false;
    } else if (status.isDenied) {
      // https://github.com/Baseflow/flutter-permission-handler/issues/1262#issuecomment-2006340937
      Permission permission = Permission.photos;
      if (defaultTargetPlatform == TargetPlatform.android &&
          ApplicationInfo.androidSDKVersion <= 32) {
        permission = Permission.storage;
      }
      // if the permission is denied, we should request the permission
      final newStatus = await permission.request();
      if (newStatus.isDenied) {
        return false;
      }
    }

    return true;
  }
}
