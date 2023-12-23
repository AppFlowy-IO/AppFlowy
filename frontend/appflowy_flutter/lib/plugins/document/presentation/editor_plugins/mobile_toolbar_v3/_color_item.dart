import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/util.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class ColorItem extends StatelessWidget {
  const ColorItem({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return MobileToolbarItemWrapper(
      size: const Size(82, 52),
      onTap: () {
        keepEditorFocusNotifier.increase();

        // showTextColorAndBackgroundColorPicker(context);
      },
      icon: FlowySvgs.m_aa_color_s,
      backgroundColor: const Color(0xFFF2F2F7),
      isSelected: false,
      showRightArrow: true,
      iconPadding: const EdgeInsets.only(
        top: 14.0,
        bottom: 14.0,
        right: 28.0,
      ),
    );
  }
}
