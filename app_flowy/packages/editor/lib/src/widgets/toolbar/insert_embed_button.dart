import 'package:flutter/material.dart';

import '../../models/documents/nodes/embed.dart';
import '../controller.dart';
import '../toolbar.dart';
import 'quill_icon_button.dart';

class InsertEmbedButton extends StatelessWidget {
  const InsertEmbedButton({
    required this.controller,
    required this.icon,
    this.iconSize = kDefaultIconSize,
    this.fillColor,
    Key? key,
  }) : super(key: key);

  final QuillController controller;
  final IconData icon;
  final double iconSize;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return QuillIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * kIconButtonFactor,
      icon: Icon(
        icon,
        size: iconSize,
        color: Theme.of(context).iconTheme.color,
      ),
      fillColor: fillColor ?? Theme.of(context).canvasColor,
      onPressed: () {
        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;
        controller.replaceText(index, length, BlockEmbed.horizontalRule, null);
      },
    );
  }
}
