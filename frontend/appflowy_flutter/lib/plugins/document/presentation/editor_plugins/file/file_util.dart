import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy_backend/dispatch/error.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
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
  String documentId,
) async {
  final documentService = DocumentService();
  Log.debug("Uploading file from local path: $localFilePath");
  final result = await documentService.uploadFile(
    localFilePath: localFilePath,
    documentId: documentId,
  );

  return result.fold(
    (s) => (s.url, null),
    (err) {
      final message = PlatformExtension.isMobile
          ? LocaleKeys.sideBar_storageLimitDialogTitleMobile.tr()
          : LocaleKeys.sideBar_storageLimitDialogTitle.tr();
      if (err.isStorageLimitExceeded) {
        return (null, message);
      }
      return (null, err.msg);
    },
  );
}
