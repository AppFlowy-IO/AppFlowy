import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:flutter/material.dart';

import '../../../generated/flowy_svgs.g.dart';

class IconWidget extends StatelessWidget {
  const IconWidget({
    super.key,
    required this.size,
    required this.data,
  });

  final IconsData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorValue = int.tryParse(data.color ?? '');
    Color? color;
    if (colorValue != null) {
      color = Color(colorValue);
    }
    return FlowySvg.string(
      data.iconContent,
      size: Size.square(size),
      color: color,
    );
  }
}
