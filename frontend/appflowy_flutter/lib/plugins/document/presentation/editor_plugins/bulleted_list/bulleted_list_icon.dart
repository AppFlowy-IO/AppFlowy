import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BulletedListIcon extends StatelessWidget {
  const BulletedListIcon({
    super.key,
    required this.node,
  });

  final Node node;

  static final bulletedListIcons = [
    FlowySvgs.bulleted_list_icon_1_s,
    FlowySvgs.bulleted_list_icon_2_s,
    FlowySvgs.bulleted_list_icon_3_s,
  ];

  int get level {
    var level = 0;
    var parent = node.parent;
    while (parent != null) {
      if (parent.type == BulletedListBlockKeys.type) {
        level++;
      }
      parent = parent.parent;
    }
    return level;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        context.read<EditorState>().editorStyle.textStyleConfiguration;
    final fontSize = textStyle.text.fontSize ?? 16.0;
    final height = textStyle.text.height ?? textStyle.lineHeight;
    final size = fontSize * height;
    final index = level % bulletedListIcons.length;
    final icon = FlowySvg(
      bulletedListIcons[index],
      size: Size.square(size * 0.8),
    );
    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      margin: const EdgeInsets.only(right: 8.0),
      alignment: Alignment.center,
      child: icon,
    );
  }
}
