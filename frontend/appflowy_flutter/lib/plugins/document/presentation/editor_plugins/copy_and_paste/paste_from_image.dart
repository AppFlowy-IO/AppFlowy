import 'dart:io';
import 'dart:typed_data';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

extension PasteFromImage on EditorState {
  static final supportedImageFormats = [
    'png',
    'jpeg',
    'gif',
  ];

  Future<bool> pasteImage(String format, Uint8List imageBytes) async {
    if (!supportedImageFormats.contains(format)) {
      return false;
    }

    final context = document.root.context;

    if (context == null) {
      return false;
    }

    final isLocalMode = context.read<DocumentBloc>().isLocalMode;

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
        'tmp_${uuid()}.$format',
      );
      await File(copyToPath).writeAsBytes(imageBytes);
      final String? path;

      if (isLocalMode) {
        path = await saveImageToLocalStorage(copyToPath);
      } else {
        final result = await saveImageToCloudStorage(copyToPath);

        final errorMessage = result.$2;

        if (errorMessage != null && context.mounted) {
          showSnackBarMessage(
            context,
            errorMessage,
          );
          return false;
        }

        path = result.$1;
      }

      if (path != null) {
        await insertImageNode(path);
      }

      await File(copyToPath).delete();
      return true;
    } catch (e) {
      Log.error('cannot copy image file', e);
      if (context.mounted) {
        showSnackBarMessage(
          context,
          LocaleKeys.document_imageBlock_error_invalidImage.tr(),
        );
      }
    }

    return false;
  }
}
