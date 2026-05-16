import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:flutter/material.dart';

import '../../../generated/flowy_svgs.g.dart';

class IconWidget extends StatelessWidget {
  const IconWidget({super.key, required this.size, required this.iconsData});

  final IconsData iconsData;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorValue = int.tryParse(iconsData.color ?? '');
    Color? color;
    if (colorValue != null) {
      color = Color(colorValue);
    }
    final svgString = iconsData.svgString;
    if (svgString == null) {
      return EmojiText(
        emoji: '❓',
        fontSize: size,
        textAlign: TextAlign.center,
      );
    }
    return FlowySvg.string(
      svgString,
      size: Size.square(size),
      color: color,
    );
  }
}
