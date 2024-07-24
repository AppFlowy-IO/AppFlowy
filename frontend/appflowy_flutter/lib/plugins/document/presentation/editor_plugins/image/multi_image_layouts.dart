import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ResizableImage;
import 'package:collection/collection.dart';
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
    required this.selectedImage,
  });

  final Node node;
  final EditorState editorState;
  final List<ImageBlockData> images;
  final ImageBlockData selectedImage;
}

class ImageBrowserLayout extends ImageBlockMultiLayout {
  const ImageBrowserLayout({
    super.key,
    required super.node,
    required super.editorState,
    required super.images,
    required super.selectedImage,
    required this.onIndexChanged,
  });

  final void Function(int) onIndexChanged;

  @override
  State<ImageBrowserLayout> createState() => _ImageBrowserLayoutState();
}

class _ImageBrowserLayoutState extends State<ImageBrowserLayout> {
  int _selectedIndex = 0;

  UserProfilePB? _userProfile;

  @override
  void initState() {
    super.initState();
    _userProfile = context.read<DocumentBloc>().state.userProfilePB;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                                    color:
                                        AFThemeExtension.of(context).strongText,
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
                            MultiImageBlockKeys.layout: widget
                                .node.attributes[MultiImageBlockKeys.layout],
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
    );
  }

  void _openInteractiveViewer(BuildContext context, [int? index]) => showDialog(
        context: context,
        builder: (_) => InteractiveImageViewer(
          userProfile: _userProfile,
          imageProvider: AFBlockImageProvider(
            images: widget.images,
            initialIndex: index ?? _selectedIndex,
          ),
        ),
      );
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
