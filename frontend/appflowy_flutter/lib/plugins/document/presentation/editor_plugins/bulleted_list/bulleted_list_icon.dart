import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BulletedListIcon extends StatefulWidget {
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

  @override
  State<BulletedListIcon> createState() => _BulletedListIconState();
}

class _BulletedListIconState extends State<BulletedListIcon> {
  int index = 0;
  double size = 0.0;

  @override
  void initState() {
    super.initState();

    final textStyle =
        context.read<EditorState>().editorStyle.textStyleConfiguration;
    final fontSize = textStyle.text.fontSize ?? 16.0;
    final height = textStyle.text.height ?? textStyle.lineHeight;
    index = level % BulletedListIcon.bulletedListIcons.length;
    size = fontSize * height;
  }

  @override
  Widget build(BuildContext context) {
    final icon = FlowySvg(
      BulletedListIcon.bulletedListIcons[index],
      size: Size.square(size * 0.8),
    );
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 8.0),
      alignment: Alignment.center,
      child: icon,
    );
  }

  int get level {
    var level = 0;
    var parent = widget.node.parent;
    while (parent != null) {
      if (parent.type == BulletedListBlockKeys.type) {
        level++;
      }
      parent = parent.parent;
    }
    return level;
  }
}
