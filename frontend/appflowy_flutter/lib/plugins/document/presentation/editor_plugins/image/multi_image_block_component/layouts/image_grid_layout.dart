import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/image_render.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/layouts/multi_image_layouts.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:collection/collection.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class ImageGridLayout extends ImageBlockMultiLayout {
  const ImageGridLayout({
    super.key,
    required super.node,
    required super.editorState,
    required super.images,
    required super.indexNotifier,
    required super.isLocalMode,
  });

  @override
  State<ImageGridLayout> createState() => _ImageGridLayoutState();
}

class _ImageGridLayoutState extends State<ImageGridLayout> {
  @override
  Widget build(BuildContext context) {
    return StaggeredGridBuilder(
      images: widget.images,
      onImageDoubleTapped: (index) {
        _openInteractiveViewer(context, index);
      },
    );
  }

  void _openInteractiveViewer(BuildContext context, int index) => showDialog(
        context: context,
        builder: (_) => InteractiveImageViewer(
          userProfile: context.read<DocumentBloc>().state.userProfilePB,
          imageProvider: AFBlockImageProvider(
            images: widget.images,
            initialIndex: index,
            onDeleteImage: (index) async {
              final transaction = widget.editorState.transaction;
              final newImages = widget.images.toList();
              newImages.removeAt(index);

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
}

/// Draws a staggered grid of images, where the pattern is based
/// on the amount of images to fill the grid at all times.
///
/// They will be alternating depending on the current index of the images, such that
/// the layout is reversed in odd segments.
///
/// If there are 4 images in the last segment, this layout will be used:
/// ┌─────┐┌─┐┌─┐
/// │     │└─┘└─┘
/// │     │┌────┐
/// └─────┘└────┘
///
/// If there are 3 images in the last segment, this layout will be used:
/// ┌─────┐┌────┐
/// │     │└────┘
/// │     │┌────┐
/// └─────┘└────┘
///
/// If there are 2 images in the last segment, this layout will be used:
/// ┌─────┐┌─────┐
/// │     ││     │
/// └─────┘└─────┘
///
/// If there is 1 image in the last segment, this layout will be used:
/// ┌──────────┐
/// │          │
/// └──────────┘
class StaggeredGridBuilder extends StatefulWidget {
  const StaggeredGridBuilder({
    super.key,
    required this.images,
    required this.onImageDoubleTapped,
  });

  final List<ImageBlockData> images;
  final void Function(int) onImageDoubleTapped;

  @override
  State<StaggeredGridBuilder> createState() => _StaggeredGridBuilderState();
}

class _StaggeredGridBuilderState extends State<StaggeredGridBuilder> {
  late final UserProfilePB? _userProfile;
  final List<List<ImageBlockData>> _splitImages = [];

  @override
  void initState() {
    super.initState();
    _userProfile = context.read<DocumentBloc>().state.userProfilePB;

    for (int i = 0; i < widget.images.length; i += 4) {
      final end = (i + 4 < widget.images.length) ? i + 4 : widget.images.length;
      _splitImages.add(widget.images.sublist(i, end));
    }
  }

  @override
  void didUpdateWidget(covariant StaggeredGridBuilder oldWidget) {
    if (widget.images.length != oldWidget.images.length) {
      _splitImages.clear();
      for (int i = 0; i < widget.images.length; i += 4) {
        final end =
            (i + 4 < widget.images.length) ? i + 4 : widget.images.length;
        _splitImages.add(widget.images.sublist(i, end));
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children:
          _splitImages.indexed.map(_buildTilesForImages).flattened.toList(),
    );
  }

  List<Widget> _buildTilesForImages((int, List<ImageBlockData>) data) {
    final index = data.$1;
    final images = data.$2;

    final isReversed = index.isOdd;

    if (images.length == 4) {
      return [
        StaggeredGridTile.count(
          crossAxisCellCount: isReversed ? 1 : 2,
          mainAxisCellCount: isReversed ? 1 : 2,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[0],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4 + 1;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[1],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: isReversed ? 2 : 1,
          mainAxisCellCount: isReversed ? 2 : 1,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4 + 2;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[2],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4 + 3;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[3],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ];
    } else if (images.length == 3) {
      return [
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: isReversed ? 1 : 2,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[0],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: isReversed ? 2 : 1,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4 + 1;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[1],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4 + 2;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[2],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ];
    } else if (images.length == 2) {
      return [
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[0],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4 + 1;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[1],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ];
    } else {
      return [
        StaggeredGridTile.count(
          crossAxisCellCount: 4,
          mainAxisCellCount: 2,
          child: GestureDetector(
            onDoubleTap: () {
              final imageIndex = index * 4;
              widget.onImageDoubleTapped(imageIndex);
            },
            child: ImageRender(
              image: images[0],
              userProfile: _userProfile,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ];
    }
  }
}
