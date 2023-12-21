import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/util.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class AlignItems extends StatelessWidget {
  const AlignItems({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return MobileToolbarItemWrapper(
      size: const Size(82, 52),
      onTap: () async {
        await editorState.alignBlock('left');
      },
      icon: FlowySvgs.m_aa_align_left_s,
      isSelected: false,
      iconPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
      ),
      showDownArrow: true,
      color: const Color(0xFFF2F2F7),
    );
  }
}
