import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/util.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class IndentAndOutdentItems extends StatelessWidget {
  const IndentAndOutdentItems({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          MobileToolbarItemWrapper(
            size: const Size(95, 52),
            icon: FlowySvgs.m_aa_outdent_s,
            iconColor:
                isOutdentable(editorState) ? null : const Color(0xFFC7C7CC),
            isSelected: false,
            enableTopRightRadius: false,
            enableBottomRightRadius: false,
            iconPadding: const EdgeInsets.symmetric(vertical: 14.0),
            backgroundColor: const Color(0xFFF2F2F7),
            onTap: () {
              outdentCommand.execute(editorState);
            },
          ),
          const ScaledVerticalDivider(),
          MobileToolbarItemWrapper(
            size: const Size(95, 52),
            icon: FlowySvgs.m_aa_indent_s,
            iconColor:
                isIndentable(editorState) ? null : const Color(0xFFC7C7CC),
            isSelected: false,
            enableTopLeftRadius: false,
            enableBottomLeftRadius: false,
            iconPadding: const EdgeInsets.symmetric(vertical: 14.0),
            backgroundColor: const Color(0xFFF2F2F7),
            onTap: () {
              indentCommand.execute(editorState);
            },
          ),
        ],
      ),
    );
  }
}
