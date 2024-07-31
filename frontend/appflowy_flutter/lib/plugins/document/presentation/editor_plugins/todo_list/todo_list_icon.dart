import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TodoListIcon extends StatelessWidget {
  const TodoListIcon({
    super.key,
    required this.node,
    required this.onCheck,
  });

  final Node node;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    // the icon height should be equal to the text height * text font size
    final textStyle =
        context.read<EditorState>().editorStyle.textStyleConfiguration;
    final fontSize = textStyle.text.fontSize ?? 16.0;
    final height = textStyle.text.height ?? textStyle.lineHeight;
    final iconSize = fontSize * height;

    final checked = node.attributes[TodoListBlockKeys.checked] ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onCheck();
      },
      child: Container(
        constraints: BoxConstraints(
          minWidth: iconSize,
          minHeight: iconSize,
        ),
        margin: const EdgeInsets.only(right: 8.0),
        alignment: Alignment.center,
        child: FlowySvg(
          checked
              ? FlowySvgs.m_todo_list_checked_s
              : FlowySvgs.m_todo_list_unchecked_s,
          blendMode: checked ? null : BlendMode.srcIn,
          size: Size.square(iconSize * 0.9),
        ),
      ),
    );
  }
}
