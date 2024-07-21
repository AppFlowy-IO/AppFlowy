import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log, UploadImageMenu;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:string_validator/string_validator.dart';

class ImagePlaceholder extends StatefulWidget {
  const ImagePlaceholder({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<ImagePlaceholder> createState() => ImagePlaceholderState();
}

class ImagePlaceholderState extends State<ImagePlaceholder> {
  final controller = PopoverController();
  final documentService = DocumentService();
  late final editorState = context.read<EditorState>();

  bool showLoading = false;
  String? errorMessage;

  bool isDraggingFiles = false;

  @override
  Widget build(BuildContext context) {
    final Widget child = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: isDraggingFiles
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: FlowyHover(
        style: HoverStyle(
          borderRadius: BorderRadius.circular(4),
        ),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const HSpace(10),
              const FlowySvg(
                FlowySvgs.image_placeholder_s,
                size: Size.square(24),
              ),
              const HSpace(10),
              ..._buildTrailing(context),
            ],
          ),
        ),
      ),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        controller: controller,
        direction: PopoverDirection.bottomWithCenterAligned,
        constraints: const BoxConstraints(
          maxWidth: 540,
          maxHeight: 360,
          minHeight: 80,
        ),
        clickHandler: PopoverClickHandler.gestureDetector,
        popupBuilder: (context) {
          return UploadImageMenu(
            allowMultipleImages: true,
            limitMaximumImageSize: !_isLocalMode(),
            supportTypes: const [
              UploadImageType.local,
              UploadImageType.url,
              UploadImageType.unsplash,
              UploadImageType.stabilityAI,
            ],
            onSelectedLocalImages: (paths) {
              controller.close();
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
                await insertLocalImages(paths);
              });
            },
            onSelectedAIImage: (url) {
              controller.close();
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
                await insertAIImage(url);
              });
            },
            onSelectedNetworkImage: (url) {
              controller.close();
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
                await insertNetworkImage(url);
              });
            },
          );
        },
        child: DropTarget(
          onDragEntered: (_) => setState(() => isDraggingFiles = true),
          onDragExited: (_) => setState(() => isDraggingFiles = false),
          onDragDone: (details) {
            // Only accept files where the mimetype is an image,
            // otherwise we assume it's a file we cannot display.
            final imageFiles = details.files
                .where((file) => file.mimeType?.startsWith('image/') ?? false)
                .toList();
            final paths = imageFiles.map((file) => file.path).toList();
            WidgetsBinding.instance.addPostFrameCallback(
              (_) async => insertLocalImages(paths),
            );
          },
          child: child,
        ),
      );
    } else {
      return MobileBlockActionButtons(
        node: widget.node,
        editorState: editorState,
        child: GestureDetector(
          onTap: () {
            editorState.updateSelectionWithReason(null, extraInfo: {});
            showUploadImageMenu();
          },
          child: child,
        ),
      );
    }
  }

  List<Widget> _buildTrailing(BuildContext context) {
    if (errorMessage != null) {
      return [
        FlowyText(
          '${LocaleKeys.document_plugins_image_imageUploadFailed.tr()}: ${errorMessage!}',
        ),
      ];
    } else if (showLoading) {
      return [
        FlowyText(
          LocaleKeys.document_imageBlock_imageIsUploading.tr(),
        ),
        const HSpace(8),
        const CircularProgressIndicator.adaptive(),
      ];
    } else {
      return [
        Flexible(
          child: FlowyText(
            PlatformExtension.isDesktop
                ? isDraggingFiles
                    ? LocaleKeys.document_plugins_image_dropImageToInsert.tr()
                    : LocaleKeys.document_plugins_image_addAnImageDesktop.tr()
                : LocaleKeys.document_plugins_image_addAnImageMobile.tr(),
          ),
        ),
      ];
    }
  }

  void showUploadImageMenu() {
    if (PlatformExtension.isDesktopOrWeb) {
      controller.show();
    } else {
      final isLocalMode = _isLocalMode();
      showMobileBottomSheet(
        context,
        title: LocaleKeys.editor_image.tr(),
        showHeader: true,
        showCloseButton: true,
        showDragHandle: true,
        builder: (context) {
          return Container(
            margin: const EdgeInsets.only(top: 12.0),
            constraints: const BoxConstraints(
              maxHeight: 340,
              minHeight: 80,
            ),
            child: UploadImageMenu(
              limitMaximumImageSize: !isLocalMode,
              supportTypes: const [
                UploadImageType.local,
                UploadImageType.url,
                UploadImageType.unsplash,
              ],
              allowMultipleImages: true,
              onSelectedLocalImages: (paths) async {
                context.pop();
                await insertLocalImages(paths);
              },
              onSelectedAIImage: (url) async {
                context.pop();
                await insertAIImage(url);
              },
              onSelectedNetworkImage: (url) async {
                context.pop();
                await insertNetworkImage(url);
              },
            ),
          );
        },
      );
    }
  }

  Future<void> insertLocalImages(List<String?> urls) async {
    controller.close();

    if (urls.isEmpty || urls.every((path) => path?.isEmpty ?? true)) {
      return;
    }

    final transaction = editorState.transaction;
    final images = await _extractImages(urls);
    if (images.isEmpty) {
      return;
    }

    if (images.length == 1) {
      final image = images.first;
      transaction.updateNode(widget.node, {
        CustomImageBlockKeys.url: image.url,
        CustomImageBlockKeys.imageType: image.type.toIntValue(),
      });
    } else {
      final root = images.first;
      final children = images.skip(1).map((data) => data.toJson()).toList();

      transaction.updateNode(widget.node, {
        CustomImageBlockKeys.url: root.url,
        CustomImageBlockKeys.imageType: root.type.toIntValue(),
        CustomImageBlockKeys.additionalImages: jsonEncode(children),
      });
    }

    await editorState.apply(transaction);
  }

  Future<List<ImageBlockData>> _extractImages(List<String?> urls) async {
    final List<ImageBlockData> images = [];
    for (final url in urls) {
      if (url == null || url.isEmpty) {
        continue;
      }

      String? path;
      String? errorMsg;
      CustomImageType imageType = CustomImageType.local;

      // If the user is using local authenticator, we save the image to local storage
      if (_isLocalMode()) {
        path = await saveImageToLocalStorage(url);
      } else {
        final documentId = context.read<DocumentBloc>().documentId;
        if (documentId.isEmpty) {
          continue;
        }
        // else we save the image to cloud storage
        setState(() {
          showLoading = true;
          errorMessage = null;
        });
        (path, errorMsg) = await saveImageToCloudStorage(url, documentId);
        setState(() {
          showLoading = false;
          errorMessage = errorMsg;
        });
        imageType = CustomImageType.internal;
      }

      if (path != null && errorMsg == null) {
        images.add(ImageBlockData(url: path, type: imageType));
      }
    }

    if (mounted && images.isEmpty) {
      // TODO(Mathias): Show error
      // showSnackBarMessage(
      //   context,
      //   errorMsg == null
      //       ? LocaleKeys.document_imageBlock_error_invalidImage.tr()
      //       : ': $errorMessage',
      // );
      // setState(() => errorMessage = errorMessage);
    }

    return images;
  }

  Future<void> insertAIImage(String url) async {
    if (url.isEmpty || !isURL(url)) {
      // show error
      return showSnackBarMessage(
        context,
        LocaleKeys.document_imageBlock_error_invalidImage.tr(),
      );
    }

    final path = await getIt<ApplicationDataStorage>().getPath();
    final imagePath = p.join(path, 'images');
    try {
      // create the directory if not exists
      final directory = Directory(imagePath);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      final uri = Uri.parse(url);
      final copyToPath = p.join(
        imagePath,
        '${uuid()}${p.extension(uri.path)}',
      );

      final response = await get(uri);
      await File(copyToPath).writeAsBytes(response.bodyBytes);
      await insertLocalImages([copyToPath]);
      await File(copyToPath).delete();
    } catch (e) {
      Log.error('cannot save image file', e);
    }
  }

  Future<void> insertNetworkImage(String url) async {
    if (url.isEmpty || !isURL(url)) {
      // show error
      return showSnackBarMessage(
        context,
        LocaleKeys.document_imageBlock_error_invalidImage.tr(),
      );
    }

    final transaction = editorState.transaction;
    transaction.updateNode(widget.node, {
      CustomImageBlockKeys.url: url,
      CustomImageBlockKeys.imageType: CustomImageType.external.toIntValue(),
    });
    await editorState.apply(transaction);
  }

  bool _isLocalMode() {
    return context.read<DocumentBloc>().isLocalMode;
  }
}
