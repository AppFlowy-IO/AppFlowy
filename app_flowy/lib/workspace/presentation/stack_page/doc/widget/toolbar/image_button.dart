import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/material.dart';

import 'toolbar_icon_button.dart';

class FlowyImageButton extends StatelessWidget {
  const FlowyImageButton({
    required this.controller,
    this.iconSize = defaultIconSize,
    this.onImagePickCallback,
    this.fillColor,
    this.filePickImpl,
    this.webImagePickImpl,
    this.mediaPickSettingSelector,
    Key? key,
  }) : super(key: key);

  final double iconSize;

  final Color? fillColor;

  final QuillController controller;

  final OnImagePickCallback? onImagePickCallback;

  final WebImagePickImpl? webImagePickImpl;

  final FilePickImpl? filePickImpl;

  final MediaPickSettingSelector? mediaPickSettingSelector;

  @override
  Widget build(BuildContext context) {
    return ToolbarIconButton(
      iconName: 'editor/image',
      width: iconSize * 1.77,
      onPressed: () => _onPressedHandler(context),
      isToggled: false,
    );
  }

  Future<void> _onPressedHandler(BuildContext context) async {
    // if (onImagePickCallback != null) {
    //   final selector = mediaPickSettingSelector ?? ImageVideoUtils.selectMediaPickSetting;
    //   final source = await selector(context);
    //   if (source != null) {
    //     if (source == MediaPickSetting.Gallery) {
    //       _pickImage(context);
    //     } else {
    //       _typeLink(context);
    //     }
    //   }
    // } else {
    //   _typeLink(context);
    // }
  }

  // void _pickImage(BuildContext context) => ImageVideoUtils.handleImageButtonTap(
  //       context,
  //       controller,
  //       ImageSource.gallery,
  //       onImagePickCallback!,
  //       filePickImpl: filePickImpl,
  //       webImagePickImpl: webImagePickImpl,
  //     );

  void _typeLink(BuildContext context) {
    TextFieldDialog(
      title: 'URL',
      value: "",
      confirm: (newValue) {
        if (newValue.isEmpty) {
          return;
        }
        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;

        controller.replaceText(index, length, BlockEmbed.image(newValue), null);
      },
    ).show(context);
  }
}
