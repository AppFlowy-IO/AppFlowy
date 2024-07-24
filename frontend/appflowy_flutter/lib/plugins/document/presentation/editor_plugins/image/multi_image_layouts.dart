import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ResizableImage;
import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:provider/provider.dart';

const _thumbnailItemSize = 100.0;

abstract class ImageBlockMultiLayout extends StatefulWidget {
  const ImageBlockMultiLayout({
    super.key,
    required this.node,
    required this.editorState,
    required this.images,
    required this.indexNotifier,
    required this.isLocalMode,
  });

  final Node node;
  final EditorState editorState;
  final List<ImageBlockData> images;
  final ValueNotifier<int> indexNotifier;
  final bool isLocalMode;
}

class ImageBrowserLayout extends ImageBlockMultiLayout {
  const ImageBrowserLayout({
    super.key,
    required super.node,
    required super.editorState,
    required super.images,
    required super.indexNotifier,
    required super.isLocalMode,
    required this.onIndexChanged,
  });

  final void Function(int) onIndexChanged;

  @override
  State<ImageBrowserLayout> createState() => _ImageBrowserLayoutState();
}

class _ImageBrowserLayoutState extends State<ImageBrowserLayout> {
  int _selectedIndex = 0;

  UserProfilePB? _userProfile;

  bool isDraggingFiles = false;

  @override
  void initState() {
    super.initState();
    _userProfile = context.read<DocumentBloc>().state.userProfilePB;
    widget.indexNotifier.addListener(onIndexChanged);
  }

  @override
  void dispose() {
    widget.indexNotifier.removeListener(onIndexChanged);
    super.dispose();
  }

  void onIndexChanged() {
    setState(
      () => _selectedIndex = widget.indexNotifier.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 400,
              width: MediaQuery.of(context).size.width,
              child: GestureDetector(
                onDoubleTap: () => _openInteractiveViewer(context),
                child: _ImageRender(
                  image: widget.images[_selectedIndex],
                  userProfile: _userProfile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const VSpace(8),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxItems =
                    (constraints.maxWidth / (_thumbnailItemSize + 4)).floor();
                final items = widget.images.take(maxItems).toList();

                return Wrap(
                  children: items.mapIndexed((index, image) {
                    final isLast = items.last == image;
                    final amountLeft = widget.images.length - items.length;
                    if (isLast && amountLeft > 0) {
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _openInteractiveViewer(
                            context,
                            maxItems - 1,
                          ),
                          child: Container(
                            width: _thumbnailItemSize,
                            height: _thumbnailItemSize,
                            padding: const EdgeInsets.all(2),
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: Corners.s8Border,
                              border: Border.all(
                                width: 2,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: Corners.s6Border,
                                image: image.type == CustomImageType.local
                                    ? DecorationImage(
                                        image: FileImage(File(image.url)),
                                        fit: BoxFit.cover,
                                        opacity: 0.5,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  if (image.type != CustomImageType.local)
                                    Positioned.fill(
                                      child: Container(
                                        clipBehavior: Clip.antiAlias,
                                        decoration: const BoxDecoration(
                                          borderRadius: Corners.s6Border,
                                        ),
                                        child: FlowyNetworkImage(
                                          url: image.url,
                                          userProfilePB: _userProfile,
                                        ),
                                      ),
                                    ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    child: Center(
                                      child: FlowyText(
                                        '+$amountLeft',
                                        color: AFThemeExtension.of(context)
                                            .strongText,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
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

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedIndex = index;
                          widget.onIndexChanged(_selectedIndex);
                        }),
                        child: _ThumbnailItem(
                          images: widget.images,
                          index: index,
                          selectedIndex: _selectedIndex,
                          userProfile: _userProfile,
                          onDeleted: () async {
                            final transaction = widget.editorState.transaction;

                            final images = widget.images.toList();
                            images.removeAt(index);

                            transaction.updateNode(
                              widget.node,
                              {
                                MultiImageBlockKeys.images:
                                    images.map((e) => e.toJson()).toList(),
                                MultiImageBlockKeys.layout: widget.node
                                    .attributes[MultiImageBlockKeys.layout],
                              },
                            );

                            await widget.editorState.apply(transaction);

                            setState(() {
                              if (_selectedIndex > 0) {
                                _selectedIndex--;
                              }
                              widget.onIndexChanged(_selectedIndex);
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        Positioned.fill(
          child: DropTarget(
            onDragEntered: (_) => setState(() => isDraggingFiles = true),
            onDragExited: (_) => setState(() => isDraggingFiles = false),
            onDragDone: (details) {
              setState(() => isDraggingFiles = false);
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
            child: !isDraggingFiles
                ? const SizedBox.shrink()
                : SizedBox.expand(
                    child: DecoratedBox(
                      decoration:
                          BoxDecoration(color: Colors.white.withOpacity(0.5)),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FlowySvg(
                              FlowySvgs.import_s,
                              size: Size.square(28),
                            ),
                            const HSpace(12),
                            Flexible(
                              child: FlowyText(
                                LocaleKeys
                                    .document_plugins_image_dropImageToInsert
                                    .tr(),
                                color: AFThemeExtension.of(context).strongText,
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _openInteractiveViewer(BuildContext context, [int? index]) => showDialog(
        context: context,
        builder: (_) => InteractiveImageViewer(
          userProfile: _userProfile,
          imageProvider: AFBlockImageProvider(
            images: widget.images,
            initialIndex: index ?? _selectedIndex,
            onDeleteImage: () async {
              final transaction = widget.editorState.transaction;
              final newImages = widget.images.toList();
              newImages.removeAt(_selectedIndex);

              setState(
                () => _selectedIndex =
                    _selectedIndex != 0 ? _selectedIndex - 1 : 0,
              );
              widget.onIndexChanged(_selectedIndex);

              if (newImages.isNotEmpty) {
                transaction.updateNode(
                  widget.node,
                  {
                    MultiImageBlockKeys.images:
                        newImages.map((e) => e.toJson()).toList(),
                    MultiImageBlockKeys.layout:
                        widget.node.attributes[MultiImageBlockKeys.layout],
                  },
                );
              } else {
                transaction.deleteNode(widget.node);
              }

              await widget.editorState.apply(transaction);
            },
          ),
        ),
      );

  Future<void> insertLocalImages(List<String?> urls) async {
    if (urls.isEmpty || urls.every((path) => path?.isEmpty ?? true)) {
      return;
    }

    final transaction = widget.editorState.transaction;
    final images = await extractAndUploadImages(context, urls, false);
    if (images.isEmpty) {
      return;
    }

    final newImages = [...widget.images, ...images];
    final imagesJson = newImages.map((image) => image.toJson()).toList();

    transaction.updateNode(widget.node, {
      MultiImageBlockKeys.images: imagesJson,
      MultiImageBlockKeys.layout: MultiImageLayout.browser.toIntValue(),
    });

    await widget.editorState.apply(transaction);
  }
}

class _ThumbnailItem extends StatefulWidget {
  const _ThumbnailItem({
    required this.images,
    required this.index,
    required this.selectedIndex,
    required this.onDeleted,
    this.userProfile,
  });

  final List<ImageBlockData> images;
  final int index;
  final int selectedIndex;
  final VoidCallback onDeleted;
  final UserProfilePB? userProfile;

  @override
  State<_ThumbnailItem> createState() => _ThumbnailItemState();
}

class _ThumbnailItemState extends State<_ThumbnailItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: Container(
        width: _thumbnailItemSize,
        height: _thumbnailItemSize,
        padding: const EdgeInsets.all(2),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: Corners.s8Border,
          border: Border.all(
            width: 2,
            color: widget.index == widget.selectedIndex
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _ImageRender(
                image: widget.images[widget.index],
                userProfile: widget.userProfile,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: AnimatedOpacity(
                opacity: isHovering ? 1 : 0,
                duration: const Duration(milliseconds: 100),
                child: FlowyTooltip(
                  message: LocaleKeys.button_delete.tr(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDeleted,
                    child: FlowyHover(
                      resetHoverOnRebuild: false,
                      style: HoverStyle(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        hoverColor: Colors.black.withOpacity(0.9),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: FlowySvg(
                          FlowySvgs.delete_s,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageRender extends StatelessWidget {
  const _ImageRender({
    required this.image,
    this.userProfile,
    this.fit = BoxFit.cover,
  });

  final ImageBlockData image;
  final UserProfilePB? userProfile;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final child = switch (image.type) {
      CustomImageType.internal || CustomImageType.external => FlowyNetworkImage(
          url: image.url,
          userProfilePB: userProfile,
          fit: fit,
        ),
      CustomImageType.local => Image.file(File(image.url), fit: fit),
    };

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(borderRadius: Corners.s6Border),
      child: child,
    );
  }
}
