import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
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
    final iconPadding = PlatformExtension.isMobile
        ? context.read<DocumentPageStyleBloc>().state.iconPadding
        : 0.0;
    final checked = node.attributes[TodoListBlockKeys.checked] ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onCheck();
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 22,
          minHeight: 22,
        ),
        margin: EdgeInsets.only(top: iconPadding, right: 8.0),
        child: FlowySvg(
          checked
              ? FlowySvgs.m_todo_list_checked_s
              : FlowySvgs.m_todo_list_unchecked_s,
          blendMode: checked ? null : BlendMode.srcIn,
        ),
      ),
    );
  }
}
