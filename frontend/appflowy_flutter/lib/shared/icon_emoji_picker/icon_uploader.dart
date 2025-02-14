import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/appflowy_network_svg.dart';
import 'package:appflowy/shared/custom_image_cache_manager.dart';
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
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:string_validator/string_validator.dart';
import 'package:universal_platform/universal_platform.dart';

@visibleForTesting
class IconUploader extends StatefulWidget {
  const IconUploader({
    super.key,
    required this.onUrl,
    required this.documentId,
    this.ensureFocus = false,
  });

  final ValueChanged<String> onUrl;
  final String documentId;
  final bool ensureFocus;

  @override
  State<IconUploader> createState() => _IconUploaderState();
}

class _IconUploaderState extends State<IconUploader> {
  bool isHovering = false;
  bool isUploading = false;

  final List<_Image> pickedImages = [];
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    /// Sometimes focus is lost due to the [SelectionGestureInterceptor] in [KeyboardServiceWidgetState]
    /// this is to ensure that focus can be regained within a short period of time
    if (widget.ensureFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || focusNode.hasFocus) return;
        focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyV,
        ): _PasteIntent(),
      },
      child: Actions(
        actions: {
          _PasteIntent: CallbackAction<_PasteIntent>(
            onInvoke: (intent) => pasteAsAnImage(),
          ),
        },
        child: Focus(
          autofocus: true,
          focusNode: focusNode,
          child: Padding(
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
                            child: pickedImages.isEmpty
                                ? dragHint()
                                : previewImage(),
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
          ),
        ),
      ),
    );
  }

  Widget dragHint() => FlowyText(
        LocaleKeys.document_imageBlock_upload_placeholder.tr(),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).hintColor,
      );

  Widget previewImage() {
    final image = pickedImages.first;
    final url = image.url;
    if (image is _FileImage) {
      if (url.endsWith(_svgSuffix)) {
        return SvgPicture.file(
          File(url),
          width: 200,
          height: 200,
        );
      }
      return Image.file(
        File(url),
        width: 200,
        height: 200,
      );
    } else if (image is _NetworkImage) {
      if (url.endsWith(_svgSuffix)) {
        return FlowyNetworkSvg(
          url,
          width: 200,
          height: 200,
        );
      }
      return FlowyNetworkImage(
        width: 200,
        height: 200,
        url: url,
      );
    }
    return const SizedBox.shrink();
  }

  void loadImage(List<XFile> files) {
    final imageFiles = files
        .where(
          (file) =>
              file.mimeType?.startsWith('image/') ??
              false ||
                  imgExtensionRegex.hasMatch(file.name) ||
                  file.name.endsWith(_svgSuffix),
        )
        .toList();
    if (imageFiles.isEmpty) return;
    if (mounted) {
      setState(() {
        pickedImages.clear();
        pickedImages.add(_FileImage(imageFiles.first.path));
      });
    }
  }

  Future<void> pickImage() async {
    if (UniversalPlatform.isDesktopOrWeb) {
      // on desktop, the users can pick a image file from folder
      final result = await getIt<FilePickerService>().pickFiles(
        dialogTitle: '',
        type: FileType.custom,
        allowedExtensions: List.of(defaultImageExtensions)..add('svg'),
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
      result = await pickedImages.first.saveToLocal();
    } else {
      result = await pickedImages.first.uploadToCloud(widget.documentId);
    }
    isUploading = false;
    if (result?.isNotEmpty ?? false) {
      widget.onUrl.call(result!);
    }
  }

  Future<void> pasteAsAnImage() async {
    final data = await getIt<ClipboardService>().getData();
    final plainText = data.plainText;
    Log.info('pasteAsAnImage plainText:$plainText');
    if (plainText == null) return;
    if (isURL(plainText) && (await validateImage(plainText))) {
      setState(() {
        pickedImages.clear();
        pickedImages.add(_NetworkImage(plainText));
      });
    }
  }

  Future<bool> validateImage(String imageUrl) async {
    Response res;
    try {
      res = await get(Uri.parse(imageUrl));
    } catch (e) {
      return false;
    }
    if (res.statusCode != 200) return false;
    final Map<String, dynamic> data = res.headers;
    return checkIfImage(data['content-type']);
  }

  bool checkIfImage(String? param) {
    if (param == 'image/jpeg' ||
        param == 'image/png' ||
        param == 'image/gif' ||
        param == 'image/tiff' ||
        param == 'image/webp' ||
        param == 'image/svg+xml' ||
        param == 'image/svg') {
      return true;
    }
    return false;
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

const _svgSuffix = '.svg';

class _PasteIntent extends Intent {}

abstract class _Image {
  String get url;

  Future<String?> saveToLocal();

  Future<String?> uploadToCloud(String documentId);

  String get pureUrl => url.split('?').first;
}

class _FileImage extends _Image {
  _FileImage(this.url);

  @override
  final String url;

  @override
  Future<String?> saveToLocal() => saveImageToLocalStorage(url);

  @override
  Future<String?> uploadToCloud(String documentId) async {
    final (url, errorMsg) = await saveImageToCloudStorage(
      this.url,
      documentId,
    );
    if (errorMsg?.isNotEmpty ?? false) {
      Log.error('upload icon image :${this.url} error :$errorMsg');
    }
    return url;
  }
}

class _NetworkImage extends _Image {
  _NetworkImage(this.url);

  @override
  final String url;

  @override
  Future<String?> saveToLocal() async {
    final file = await CustomImageCacheManager().downloadFile(pureUrl);
    return file.file.path;
  }

  @override
  Future<String?> uploadToCloud(String documentId) async {
    final file = await CustomImageCacheManager().downloadFile(pureUrl);
    final (url, errorMsg) = await saveImageToCloudStorage(
      file.file.path,
      documentId,
    );
    if (errorMsg?.isNotEmpty ?? false) {
      Log.error('upload icon image :${this.url} error :$errorMsg');
    }
    return url;
  }
}
