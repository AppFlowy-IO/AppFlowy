import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/upload_image_menu.dart';
import 'package:appflowy/shared/patterns/file_type_patterns.dart';
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
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:string_validator/string_validator.dart';

class ImagePlaceholder extends StatefulWidget {
  const ImagePlaceholder({super.key, required this.node});

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
              FlowySvg(
                FlowySvgs.slash_menu_icon_image_s,
                size: const Size.square(24),
                color: Theme.of(context).hintColor,
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
            ],
            onSelectedLocalImages: (paths) {
              controller.close();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final List<String> items = List.from(
                  paths.where((url) => url != null && url.isNotEmpty),
                );
                if (items.isNotEmpty) {
                  await insertMultipleLocalImages(items);
                }
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
                .where(
                  (file) =>
                      file.mimeType?.startsWith('image/') ??
                      false || imgExtensionRegex.hasMatch(file.name),
                )
                .toList();
            final paths = imageFiles.map((file) => file.path).toList();

            WidgetsBinding.instance.addPostFrameCallback(
              (_) async => insertMultipleLocalImages(paths),
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
        Flexible(
          child: FlowyText(
            '${LocaleKeys.document_plugins_image_imageUploadFailed.tr()}: ${errorMessage!}',
            maxLines: 3,
          ),
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
            color: Theme.of(context).hintColor,
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
              onSelectedLocalImages: (paths) async {
                context.pop();

                final List<String> items = List.from(
                  paths.where((url) => url != null && url.isNotEmpty),
                );

                await insertMultipleLocalImages(items);
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

  Future<void> insertMultipleLocalImages(List<String> urls) async {
    controller.close();

    setState(() {
      showLoading = true;
      errorMessage = null;
    });

    bool hasError = false;

    if (_isLocalMode()) {
      if (urls.isEmpty) {
        return;
      }

      final first = urls.removeAt(0);
      final firstPath = await saveImageToLocalStorage(first);
      final transaction = editorState.transaction;
      transaction.updateNode(widget.node, {
        CustomImageBlockKeys.url: firstPath,
        CustomImageBlockKeys.imageType: CustomImageType.local.toIntValue(),
      });

      if (urls.isNotEmpty) {
        // Create new nodes for the rest of the images:
        final paths = await Future.wait(urls.map(saveImageToLocalStorage));
        paths.removeWhere((url) => url == null || url.isEmpty);

        transaction.insertNodes(
          widget.node.path.next,
          paths.map((url) => customImageNode(url: url!)).toList(),
        );
      }

      await editorState.apply(transaction);
    } else {
      final transaction = editorState.transaction;

      bool isFirst = true;
      for (final url in urls) {
        // Upload to cloud
        final (path, error) = await saveImageToCloudStorage(
          url,
          context.read<DocumentBloc>().documentId,
        );

        if (error != null) {
          hasError = true;

          if (isFirst) {
            setState(() => errorMessage = error);
          }

          continue;
        }

        if (path != null) {
          if (isFirst) {
            isFirst = false;
            transaction.updateNode(widget.node, {
              CustomImageBlockKeys.url: path,
              CustomImageBlockKeys.imageType:
                  CustomImageType.internal.toIntValue(),
            });
          } else {
            transaction.insertNode(
              widget.node.path.next,
              customImageNode(
                url: path,
                type: CustomImageType.internal,
              ),
            );
          }
        }
      }

      await editorState.apply(transaction);
    }

    setState(() => showLoading = false);

    if (hasError && mounted) {
      showSnapBar(
        context,
        LocaleKeys.document_imageBlock_error_multipleImagesFailed.tr(),
      );
    }
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
      await insertMultipleLocalImages([copyToPath]);
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
