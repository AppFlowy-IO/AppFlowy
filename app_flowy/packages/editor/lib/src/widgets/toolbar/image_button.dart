import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/documents/nodes/embed.dart';
import '../../utils/media_pick_setting.dart';
import '../controller.dart';
import '../link_dialog.dart';
import '../toolbar.dart';
import 'image_video_utils.dart';
import 'quill_icon_button.dart';

class ImageButton extends StatelessWidget {
  const ImageButton({
    required this.icon,
    required this.controller,
    this.iconSize = kDefaultIconSize,
    this.onImagePickCallback,
    this.fillColor,
    this.filePickImpl,
    this.webImagePickImpl,
    this.mediaPickSettingSelector,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final double iconSize;

  final Color? fillColor;

  final QuillController controller;

  final OnImagePickCallback? onImagePickCallback;

  final WebImagePickImpl? webImagePickImpl;

  final FilePickImpl? filePickImpl;

  final MediaPickSettingSelector? mediaPickSettingSelector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return QuillIconButton(
      icon: Icon(icon, size: iconSize, color: theme.iconTheme.color),
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * 1.77,
      fillColor: fillColor ?? theme.canvasColor,
      onPressed: () => _onPressedHandler(context),
    );
  }

  Future<void> _onPressedHandler(BuildContext context) async {
    if (onImagePickCallback != null) {
      final selector =
          mediaPickSettingSelector ?? ImageVideoUtils.selectMediaPickSetting;
      final source = await selector(context);
      if (source != null) {
        if (source == MediaPickSetting.Gallery) {
          _pickImage(context);
        } else {
          _typeLink(context);
        }
      }
    } else {
      _typeLink(context);
    }
  }

  void _pickImage(BuildContext context) => ImageVideoUtils.handleImageButtonTap(
        context,
        controller,
        ImageSource.gallery,
        onImagePickCallback!,
        filePickImpl: filePickImpl,
        webImagePickImpl: webImagePickImpl,
      );

  void _typeLink(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (_) => const LinkDialog(),
    ).then(_linkSubmitted);
  }

  void _linkSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = controller.selection.baseOffset;
      final length = controller.selection.extentOffset - index;

      controller.replaceText(index, length, BlockEmbed.image(value), null);
    }
  }
}
