import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/permission/permission_checker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadImageFileWidget extends StatelessWidget {
  const UploadImageFileWidget({
    super.key,
    required this.onPickFiles,
    this.allowedExtensions = const ['jpg', 'png', 'jpeg'],
    this.allowMultipleImages = false,
  });

  final void Function(List<String?>) onPickFiles;
  final List<String> allowedExtensions;
  final bool allowMultipleImages;

  @override
  Widget build(BuildContext context) {
    Widget child = FlowyButton(
      showDefaultBoxDecorationOnMobile: true,
      radius: PlatformExtension.isMobile ? BorderRadius.circular(8.0) : null,
      text: Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        child: FlowyText(
          LocaleKeys.document_imageBlock_upload_placeholder.tr(),
        ),
      ),
      onTap: () => _uploadImage(context),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      child = FlowyHover(child: child);
    } else {
      child = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: child,
      );
    }

    return child;
  }

  Future<void> _uploadImage(BuildContext context) async {
    if (PlatformExtension.isDesktopOrWeb) {
      // on desktop, the users can pick a image file from folder
      final result = await getIt<FilePickerService>().pickFiles(
        dialogTitle: '',
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultipleImages,
      );
      onPickFiles(result?.files.map((f) => f.path).toList() ?? const []);
    } else {
      final photoPermission =
          await PermissionChecker.checkPhotoPermission(context);
      if (!photoPermission) {
        Log.error('Has no permission to access the photo library');
        return;
      }
      // on mobile, the users can pick a image file from camera or image library
      final result = await ImagePicker().pickMultiImage();
      onPickFiles(result.map((f) => f.path).toList());
    }
  }
}
