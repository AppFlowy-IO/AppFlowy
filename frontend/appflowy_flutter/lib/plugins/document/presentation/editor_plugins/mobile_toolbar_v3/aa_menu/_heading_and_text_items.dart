import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/util.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class HeadingsAndTextItems extends StatelessWidget {
  const HeadingsAndTextItems({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _HeadingOrTextItem(
          icon: FlowySvgs.m_aa_h1_m,
          blockType: HeadingBlockKeys.type,
          editorState: editorState,
          level: 1,
        ),
        _HeadingOrTextItem(
          icon: FlowySvgs.m_aa_h2_m,
          blockType: HeadingBlockKeys.type,
          editorState: editorState,
          level: 2,
        ),
        _HeadingOrTextItem(
          icon: FlowySvgs.m_aa_h3_m,
          blockType: HeadingBlockKeys.type,
          editorState: editorState,
          level: 3,
        ),
        _HeadingOrTextItem(
          icon: FlowySvgs.m_aa_paragraph_m,
          blockType: ParagraphBlockKeys.type,
          editorState: editorState,
        ),
      ],
    );
  }
}

class _HeadingOrTextItem extends StatelessWidget {
  const _HeadingOrTextItem({
    required this.icon,
    required this.blockType,
    required this.editorState,
    this.level,
  });

  final FlowySvgData icon;
  final String blockType;
  final EditorState editorState;
  final int? level;

  @override
  Widget build(BuildContext context) {
    final isSelected = editorState.isBlockTypeSelected(
      blockType,
      level: level,
    );
    final padding = level != null
        ? EdgeInsets.symmetric(
            vertical: 14.0 - (3 - level!) * 3.0,
          )
        : const EdgeInsets.symmetric(
            vertical: 16.0,
          );
    return MobileToolbarMenuItemWrapper(
      size: const Size(76, 52),
      onTap: () async => _convert(isSelected),
      icon: icon,
      isSelected: isSelected,
      iconPadding: padding,
    );
  }

  Future<void> _convert(bool isSelected) async {
    await editorState.convertBlockType(
      blockType,
      isSelected: isSelected,
      extraAttributes: level != null
          ? {
              HeadingBlockKeys.level: level!,
            }
          : null,
      selectionExtraInfo: {
        selectionExtraInfoDoNotAttachTextService: true,
        selectionExtraInfoDisableFloatingToolbar: true,
      },
    );
    unawaited(
      editorState.updateSelectionWithReason(
        editorState.selection,
        extraInfo: {
          selectionExtraInfoDisableFloatingToolbar: true,
          selectionExtraInfoDoNotAttachTextService: true,
        },
      ),
    );
  }
}
