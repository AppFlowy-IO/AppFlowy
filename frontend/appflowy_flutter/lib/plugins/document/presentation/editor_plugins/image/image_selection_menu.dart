import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

final customImageMenuItem = SelectionMenuItem(
  getName: () => AppFlowyEditorL10n.current.image,
  icon: (_, isSelected, style) => SelectionMenuIconWidget(
    name: 'image',
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['image', 'picture', 'img', 'photo'],
  handler: (editorState, _, __) async {
    // use the key to retrieve the state of the image block to show the popover automatically
    final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
    await editorState.insertEmptyImageBlock(imagePlaceholderKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      imagePlaceholderKey.currentState?.controller.show();
    });
  },
);

final multiImageMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_plugins_photoGallery_name.tr(),
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.image_s,
    size: const Size.square(16.0),
    isSelected: isSelected,
    style: style,
  ),
  keywords: [
    LocaleKeys.document_plugins_photoGallery_imageKeyword.tr(),
    LocaleKeys.document_plugins_photoGallery_imageGalleryKeyword.tr(),
    LocaleKeys.document_plugins_photoGallery_photoKeyword.tr(),
    LocaleKeys.document_plugins_photoGallery_photoBrowserKeyword.tr(),
    LocaleKeys.document_plugins_photoGallery_galleryKeyword.tr(),
  ],
  handler: (editorState, _, __) async {
    final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
    await editorState.insertEmptyMultiImageBlock(imagePlaceholderKey);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => imagePlaceholderKey.currentState?.controller.show(),
    );
  },
);

extension InsertImage on EditorState {
  Future<void> insertEmptyImageBlock(GlobalKey key) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final path = selection.end.path;
    final node = getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final emptyImage = imageNode(url: '')
      ..extraInfos = {kImagePlaceholderKey: key};

    final insertedPath = delta.isEmpty ? path : path.next;
    final transaction = this.transaction
      ..insertNode(insertedPath, emptyImage)
      ..insertNode(insertedPath, paragraphNode())
      ..afterSelection = Selection.collapsed(Position(path: insertedPath.next));

    return apply(transaction);
  }

  Future<void> insertEmptyMultiImageBlock(GlobalKey key) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final path = selection.end.path;
    final node = getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final emptyBlock = multiImageNode()
      ..extraInfos = {kMultiImagePlaceholderKey: key};

    final insertedPath = delta.isEmpty ? path : path.next;
    final transaction = this.transaction
      ..insertNode(insertedPath, emptyBlock)
      ..insertNode(insertedPath, paragraphNode())
      ..afterSelection = Selection.collapsed(Position(path: insertedPath.next));

    return apply(transaction);
  }
}
