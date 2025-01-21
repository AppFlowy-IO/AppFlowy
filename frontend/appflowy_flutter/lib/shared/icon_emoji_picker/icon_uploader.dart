import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/shared/patterns/file_type_patterns.dart';
import 'package:appflowy/shared/permission/permission_checker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/util/default_extensions.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/style_widget/primary_rounded_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_platform/universal_platform.dart';

@visibleForTesting
class IconUploader extends StatefulWidget {
  const IconUploader({
    super.key,
    required this.onUrl,
    required this.documentId,
  });

  final ValueChanged<String> onUrl;
  final String documentId;

  @override
  State<IconUploader> createState() => _IconUploaderState();
}

class _IconUploaderState extends State<IconUploader> {
  bool isHovering = false;
  bool isUploading = false;

  final List<String> pickedImages = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: DropTarget(
              /// there is an issue with multiple DropTargets
              /// see https://github.com/MixinNetwork/flutter-plugins/issues/2
              enable: false,
              onDragEntered: (_) => setState(() => isHovering = true),
              onDragExited: (_) => setState(() => isHovering = false),
              onDragDone: (details) => loadImage(details.files),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => pickImage(),
                  child: DottedBorder(
                    dashPattern: const [3, 3],
                    radius: const Radius.circular(8),
                    borderType: BorderType.RRect,
                    color: isHovering
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).hintColor,
                    child: Center(
                      child: pickedImages.isEmpty ? dragHint() : previewImage(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ConfirmButton(
                onTap: uploadImage,
                enable: pickedImages.isNotEmpty,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dragHint() => FlowyText(
        LocaleKeys.document_imageBlock_upload_placeholder.tr(),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).hintColor,
      );

  Widget previewImage() => Image.file(
        File(pickedImages.first),
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );

  void loadImage(List<XFile> files) {
    final imageFiles = files
        .where(
          (file) =>
              file.mimeType?.startsWith('image/') ??
              false || imgExtensionRegex.hasMatch(file.name),
        )
        .toList();
    if (imageFiles.isEmpty) return;
    if (mounted) {
      setState(() {
        pickedImages.clear();
        pickedImages.add(imageFiles.first.path);
      });
    }
  }

  Future<void> pickImage() async {
    if (UniversalPlatform.isDesktopOrWeb) {
      // on desktop, the users can pick a image file from folder
      final result = await getIt<FilePickerService>().pickFiles(
        dialogTitle: '',
        type: FileType.custom,
        allowedExtensions: defaultImageExtensions,
      );
      loadImage(result?.files.map((f) => f.xFile).toList() ?? const []);
    } else {
      final photoPermission =
          await PermissionChecker.checkPhotoPermission(context);
      if (!photoPermission) {
        Log.error('Has no permission to access the photo library');
        return;
      }
      // on mobile, the users can pick a image file from camera or image library
      final result = await ImagePicker().pickMultiImage();
      loadImage(result);
    }
  }

  Future<void> uploadImage() async {
    if (pickedImages.isEmpty || isUploading) return;
    isUploading = true;
    String? result;
    final userProfileResult = await UserBackendService.getCurrentUserProfile();
    final userProfile = userProfileResult.fold(
      (userProfile) => userProfile,
      (l) => null,
    );
    final isLocalMode = (userProfile?.authenticator ?? AuthenticatorPB.Local) ==
        AuthenticatorPB.Local;
    if (isLocalMode) {
      result = await saveImageToLocalStorage(pickedImages.first);
    } else {
      final (url, errorMsg) = await saveImageToCloudStorage(
        pickedImages.first,
        widget.documentId,
      );
      result = url;
      if (errorMsg?.isNotEmpty ?? false) {
        Log.error('upload icon image error :$errorMsg');
      }
    }
    isUploading = false;
    if (result?.isNotEmpty ?? false) {
      widget.onUrl.call(result!);
    }
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onTap, this.enable = true});

  final VoidCallback onTap;
  final bool enable;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Opacity(
        opacity: enable ? 1.0 : 0.5,
        child: PrimaryRoundedButton(
          text: LocaleKeys.button_confirm.tr(),
          onTap: enable ? onTap : null,
        ),
      ),
    );
  }
}
