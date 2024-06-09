import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/shared/custom_image_cache_manager.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_extension.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:path/path.dart' as p;

Future<String?> saveImageToLocalStorage(String localImagePath) async {
  final path = await getIt<ApplicationDataStorage>().getPath();
  final imagePath = p.join(
    path,
    'images',
  );
  try {
    // create the directory if not exists
    final directory = Directory(imagePath);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final copyToPath = p.join(
      imagePath,
      '${uuid()}${p.extension(localImagePath)}',
    );
    await File(localImagePath).copy(
      copyToPath,
    );
    return copyToPath;
  } catch (e) {
    Log.error('cannot save image file', e);
    return null;
  }
}

Future<(String? path, String? errorMessage)> saveImageToCloudStorage(
  String localImagePath,
) async {
  final size = localImagePath.fileSize;
  if (size == null || size > 10 * 1024 * 1024) {
    // 10MB
    return (
      null,
      LocaleKeys.document_imageBlock_uploadImageErrorImageSizeTooBig.tr(),
    );
  }
  final documentService = DocumentService();
  final result = await documentService.uploadFile(
    localFilePath: localImagePath,
    isAsync: false,
  );
  return result.fold(
    (s) async {
      await CustomImageCacheManager().putFile(
        s.url,
        File(localImagePath).readAsBytesSync(),
      );
      return (s.url, null);
    },
    (e) => (null, e.msg),
  );
}
