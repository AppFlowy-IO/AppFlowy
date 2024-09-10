import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/block_menu/block_menu_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/upload_image_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide UploadImageMenu, Log;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:string_validator/string_validator.dart';

const _interceptorKey = 'add-image';

class MultiImageMenu extends StatefulWidget {
  const MultiImageMenu({
    super.key,
    required this.node,
    required this.state,
    required this.indexNotifier,
    this.isLocalMode = true,
    required this.onImageDeleted,
  });

  final Node node;
  final MultiImageBlockComponentState state;
  final ValueNotifier<int> indexNotifier;
  final bool isLocalMode;
  final VoidCallback onImageDeleted;

  @override
  State<MultiImageMenu> createState() => _MultiImageMenuState();
}

class _MultiImageMenuState extends State<MultiImageMenu> {
  final gestureInterceptor = SelectionGestureInterceptor(
    key: _interceptorKey,
    canTap: (details) => false,
  );

  final PopoverController controller = PopoverController();
  final PopoverController layoutController = PopoverController();
  late List<ImageBlockData> images;
  late final EditorState editorState;

  @override
  void initState() {
    super.initState();
    editorState = context.read<EditorState>();
    images = MultiImageData.fromJson(
      widget.node.attributes[MultiImageBlockKeys.images] ?? {},
    ).images;
  }

  @override
  void dispose() {
    allowMenuClose();
    controller.close();
    layoutController.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MultiImageMenu oldWidget) {
    images = MultiImageData.fromJson(
      widget.node.attributes[MultiImageBlockKeys.images] ?? {},
    ).images;

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = MultiImageLayout.fromIntValue(
      widget.node.attributes[MultiImageBlockKeys.layout] ?? 0,
    );
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          const HSpace(4),
          AppFlowyPopover(
            controller: controller,
            direction: PopoverDirection.bottomWithRightAligned,
            onClose: allowMenuClose,
            constraints: const BoxConstraints(
              maxWidth: 540,
              maxHeight: 360,
              minHeight: 80,
            ),
            offset: const Offset(0, 10),
            popupBuilder: (context) {
              preventMenuClose();
              return UploadImageMenu(
                allowMultipleImages: true,
                supportTypes: const [
                  UploadImageType.local,
                  UploadImageType.url,
                  UploadImageType.unsplash,
                ],
                onSelectedLocalImages: insertLocalImages,
                onSelectedAIImage: insertAIImage,
                onSelectedNetworkImage: insertNetworkImage,
              );
            },
            child: MenuBlockButton(
              tooltip:
                  LocaleKeys.document_plugins_photoGallery_addImageTooltip.tr(),
              iconData: FlowySvgs.add_s,
              onTap: () {},
            ),
          ),
          const HSpace(4),
          AppFlowyPopover(
            controller: layoutController,
            onClose: allowMenuClose,
            direction: PopoverDirection.bottomWithRightAligned,
            offset: const Offset(0, 10),
            constraints: const BoxConstraints(
              maxHeight: 300,
              maxWidth: 300,
            ),
            popupBuilder: (context) {
              preventMenuClose();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LayoutSelector(
                    selectedLayout: layout,
                    onSelected: (layout) {
                      allowMenuClose();
                      layoutController.close();
                      final transaction = editorState.transaction;
                      transaction.updateNode(widget.node, {
                        MultiImageBlockKeys.images:
                            widget.node.attributes[MultiImageBlockKeys.images],
                        MultiImageBlockKeys.layout: layout.toIntValue(),
                      });
                      editorState.apply(transaction);
                    },
                  ),
                ],
              );
            },
            child: MenuBlockButton(
              tooltip: LocaleKeys
                  .document_plugins_photoGallery_changeLayoutTooltip
                  .tr(),
              iconData: FlowySvgs.edit_layout_s,
              onTap: () {},
            ),
          ),
          const HSpace(4),
          MenuBlockButton(
            tooltip: LocaleKeys.document_imageBlock_openFullScreen.tr(),
            iconData: FlowySvgs.full_view_s,
            onTap: openFullScreen,
          ),

          // disable the copy link button if the image is hosted on appflowy cloud
          // because the url needs the verification token to be accessible
          if (layout == MultiImageLayout.browser &&
              !images[widget.indexNotifier.value].url.isAppFlowyCloudUrl) ...[
            const HSpace(4),
            MenuBlockButton(
              tooltip: LocaleKeys.editor_copyLink.tr(),
              iconData: FlowySvgs.copy_s,
              onTap: copyImageLink,
            ),
          ],
          const _Divider(),
          MenuBlockButton(
            tooltip: LocaleKeys.document_plugins_photoGallery_deleteBlockTooltip
                .tr(),
            iconData: FlowySvgs.delete_s,
            onTap: deleteImage,
          ),
          const HSpace(4),
        ],
      ),
    );
  }

  void copyImageLink() {
    Clipboard.setData(
      ClipboardData(text: images[widget.indexNotifier.value].url),
    );
    showSnackBarMessage(
      context,
      LocaleKeys.document_plugins_image_copiedToPasteBoard.tr(),
    );
  }

  Future<void> deleteImage() async {
    final node = widget.node;
    final editorState = context.read<EditorState>();
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    transaction.afterSelection = null;
    await editorState.apply(transaction);
  }

  void openFullScreen() {
    showDialog(
      context: context,
      builder: (_) => InteractiveImageViewer(
        userProfile: context.read<DocumentBloc>().state.userProfilePB,
        imageProvider: AFBlockImageProvider(
          images: images,
          initialIndex: widget.indexNotifier.value,
          onDeleteImage: (index) async {
            final transaction = editorState.transaction;
            final newImages = List<ImageBlockData>.from(images);
            newImages.removeAt(index);

            images = newImages;
            widget.onImageDeleted();

            final imagesJson =
                newImages.map((image) => image.toJson()).toList();
            transaction.updateNode(widget.node, {
              MultiImageBlockKeys.images: imagesJson,
              MultiImageBlockKeys.layout:
                  widget.node.attributes[MultiImageBlockKeys.layout],
            });

            await editorState.apply(transaction);
          },
        ),
      ),
    );
  }

  void preventMenuClose() {
    widget.state.alwaysShowMenu = true;
    editorState.service.selectionService.registerGestureInterceptor(
      gestureInterceptor,
    );
  }

  void allowMenuClose() {
    widget.state.alwaysShowMenu = false;
    editorState.service.selectionService.unregisterGestureInterceptor(
      _interceptorKey,
    );
  }

  Future<void> insertLocalImages(List<XFile> files) async {
    controller.close();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final urls = files
          .map((file) => file.path)
          .where((path) => path.isNotEmpty)
          .toList();

      if (urls.isEmpty || urls.every((url) => url.isEmpty)) {
        return;
      }

      final transaction = editorState.transaction;
      final newImages =
          await extractAndUploadImages(context, urls, widget.isLocalMode);
      if (newImages.isEmpty) {
        return;
      }

      final imagesJson =
          [...images, ...newImages].map((i) => i.toJson()).toList();
      transaction.updateNode(widget.node, {
        MultiImageBlockKeys.images: imagesJson,
        MultiImageBlockKeys.layout:
            widget.node.attributes[MultiImageBlockKeys.layout],
      });

      await editorState.apply(transaction);
      setState(() => images = newImages);
    });
  }

  Future<void> insertAIImage(String url) async {
    controller.close();

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
      await insertLocalImages([XFile(copyToPath)]);
      await File(copyToPath).delete();
    } catch (e) {
      Log.error('cannot save image file', e);
    }
  }

  Future<void> insertNetworkImage(String url) async {
    controller.close();

    if (url.isEmpty || !isURL(url)) {
      // show error
      return showSnackBarMessage(
        context,
        LocaleKeys.document_imageBlock_error_invalidImage.tr(),
      );
    }

    final transaction = editorState.transaction;

    final newImages = [
      ...images,
      ImageBlockData(url: url, type: CustomImageType.external),
    ];

    final imagesJson = newImages.map((image) => image.toJson()).toList();
    transaction.updateNode(widget.node, {
      MultiImageBlockKeys.images: imagesJson,
      MultiImageBlockKeys.layout:
          widget.node.attributes[MultiImageBlockKeys.layout],
    });

    await editorState.apply(transaction);
    setState(() => images = newImages);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(width: 1, color: Colors.grey),
    );
  }
}

class _LayoutSelector extends StatelessWidget {
  const _LayoutSelector({
    required this.selectedLayout,
    required this.onSelected,
  });

  final MultiImageLayout selectedLayout;
  final Function(MultiImageLayout) onSelected;

  @override
  Widget build(BuildContext context) {
    return SeparatedRow(
      separatorBuilder: () => const HSpace(6),
      mainAxisSize: MainAxisSize.min,
      children: MultiImageLayout.values
          .map(
            (layout) => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onSelected(layout),
                child: Container(
                  height: 80,
                  width: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: selectedLayout == layout
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                    borderRadius: Corners.s8Border,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlowySvg(
                        layout.icon,
                        color: AFThemeExtension.of(context).strongText,
                        size: const Size.square(24),
                      ),
                      const VSpace(6),
                      FlowyText(layout.label),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
