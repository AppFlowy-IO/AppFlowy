import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/shared/custom_image_cache_manager.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/xfile_ext.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/dispatch/error.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_impl.dart';
import 'package:flowy_infra/platform_extension.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

Future<String?> saveFileToLocalStorage(String localFilePath) async {
  final path = await getIt<ApplicationDataStorage>().getPath();
  final filePath = p.join(path, 'files');

  try {
    // create the directory if not exists
    final directory = Directory(filePath);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final copyToPath = p.join(
      filePath,
      '${uuid()}${p.extension(localFilePath)}',
    );
    await File(localFilePath).copy(
      copyToPath,
    );
    return copyToPath;
  } catch (e) {
    Log.error('cannot save file', e);
    return null;
  }
}

Future<(String? path, String? errorMessage)> saveFileToCloudStorage(
  String localFilePath,
  String documentId, [
  bool isImage = false,
]) async {
  final documentService = DocumentService();
  Log.debug("Uploading file from local path: $localFilePath");
  final result = await documentService.uploadFile(
    localFilePath: localFilePath,
    documentId: documentId,
  );

  return result.fold(
    (s) async {
      if (isImage) {
        await CustomImageCacheManager().putFile(
          s.url,
          File(localFilePath).readAsBytesSync(),
        );
      }

      return (s.url, null);
    },
    (err) {
      final message = Platform.isIOS
          ? LocaleKeys.sideBar_storageLimitDialogTitleIOS.tr()
          : LocaleKeys.sideBar_storageLimitDialogTitle.tr();
      if (err.isStorageLimitExceeded) {
        return (null, message);
      }
      return (null, err.msg);
    },
  );
}

/// Downloads a MediaFilePB
///
/// On Mobile the file is fetched first using HTTP, and then saved using FilePicker.
/// On Desktop the files location is picked first using FilePicker, and then the file is saved.
///
Future<void> downloadMediaFile(
  BuildContext context,
  MediaFilePB file, {
  VoidCallback? onDownloadBegin,
  VoidCallback? onDownloadEnd,
  UserProfilePB? userProfile,
}) async {
  if ([
    FileUploadTypePB.NetworkFile,
    FileUploadTypePB.LocalFile,
  ].contains(file.uploadType)) {
    /// When the file is a network file or a local file, we can directly open the file.
    await afLaunchUrl(Uri.parse(file.url));
  } else {
    if (userProfile == null) {
      return showSnapBar(
        context,
        "Failed to download file, could not find user token",
      );
    }

    final uri = Uri.parse(file.url);
    final token = jsonDecode(userProfile.token)['access_token'];

    if (PlatformExtension.isMobile) {
      onDownloadBegin?.call();

      final response =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final tempFile = File(uri.pathSegments.last);
        await FilePicker().saveFile(
          fileName: p.basename(tempFile.path),
          bytes: response.bodyBytes,
        );
      } else if (context.mounted) {
        showSnapBar(
          context,
          LocaleKeys.document_plugins_image_imageDownloadFailed.tr(),
        );
      }

      onDownloadEnd?.call();
    } else {
      final savePath = await FilePicker().saveFile(fileName: file.name);
      if (savePath == null) {
        return;
      }

      final response =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final imgFile = File(savePath);
        await imgFile.writeAsBytes(response.bodyBytes);
      } else if (context.mounted) {
        showSnapBar(
          context,
          LocaleKeys.document_plugins_image_imageDownloadFailed.tr(),
        );
      }
    }
  }
}

Future<void> insertLocalFile(
  BuildContext context,
  XFile file, {
  required String documentId,
  UserProfilePB? userProfile,
  void Function(String, bool)? onUploadSuccess,
}) async {
  if (file.path.isEmpty) return;

  final fileType = file.fileType.toMediaFileTypePB();

  // Check upload type
  final isLocalMode = (userProfile?.authenticator ?? AuthenticatorPB.Local) ==
      AuthenticatorPB.Local;

  String? path;
  String? errorMsg;
  if (isLocalMode) {
    path = await saveFileToLocalStorage(file.path);
  } else {
    (path, errorMsg) = await saveFileToCloudStorage(
      file.path,
      documentId,
      fileType == MediaFileTypePB.Image,
    );
  }

  if (errorMsg != null) {
    return showSnackBarMessage(context, errorMsg);
  }

  if (path == null) {
    return;
  }

  onUploadSuccess?.call(path, isLocalMode);
}
