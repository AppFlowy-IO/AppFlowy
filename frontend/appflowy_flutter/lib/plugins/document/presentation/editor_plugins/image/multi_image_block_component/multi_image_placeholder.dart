import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/upload_image_menu.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide UploadImageMenu, Log;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:string_validator/string_validator.dart';

class MultiImagePlaceholder extends StatefulWidget {
  const MultiImagePlaceholder({super.key, required this.node});

  final Node node;

  @override
  State<MultiImagePlaceholder> createState() => MultiImagePlaceholderState();
}

class MultiImagePlaceholderState extends State<MultiImagePlaceholder> {
  final controller = PopoverController();
  final documentService = DocumentService();
  late final editorState = context.read<EditorState>();

  bool isDraggingFiles = false;

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.photo_library_outlined, size: 24),
              const HSpace(10),
              FlowyText(
                PlatformExtension.isDesktop
                    ? isDraggingFiles
                        ? LocaleKeys.document_plugins_image_dropImageToInsert
                            .tr()
                        : LocaleKeys.document_plugins_image_addAnImageDesktop
                            .tr()
                    : LocaleKeys.document_plugins_image_addAnImageMobile.tr(),
              ),
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
        popupBuilder: (_) {
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
            // or the file extension is a known image format,
            // otherwise we assume it's a file we cannot display.
            final imageFiles = details.files
                .where(
                  (file) =>
                      file.mimeType?.startsWith('image/') ??
                      false || imgExtensionRegex.hasMatch(file.name),
                )
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
              allowMultipleImages: true,
              supportTypes: const [
                UploadImageType.local,
                UploadImageType.url,
                UploadImageType.unsplash,
              ],
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
    final images = await extractAndUploadImages(context, urls, _isLocalMode());
    if (images.isEmpty) {
      return;
    }

    final imagesJson = images.map((image) => image.toJson()).toList();

    transaction.updateNode(widget.node, {
      MultiImageBlockKeys.images: imagesJson,
      // Default to Browser layout
      MultiImageBlockKeys.layout: MultiImageLayout.browser.toIntValue(),
    });

    await editorState.apply(transaction);
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

    final images = [
      ImageBlockData(
        url: url,
        type: CustomImageType.external,
      ),
    ];

    transaction.updateNode(widget.node, {
      MultiImageBlockKeys.images:
          images.map((image) => image.toJson()).toList(),
      // Default to Browser layout
      MultiImageBlockKeys.layout: MultiImageLayout.browser.toIntValue(),
    });
    await editorState.apply(transaction);
  }

  bool _isLocalMode() {
    return context.read<DocumentBloc>().isLocalMode;
  }
}
