import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

final mobileAlignToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (_, editorState, __) {
    return onlyShowInTextType(editorState)
        ? const FlowySvg(
            FlowySvgs.toolbar_align_center_s,
            size: Size.square(32),
          )
        : null;
  },
  itemMenuBuilder: (_, editorState, ___) {
    final selection = editorState.selection;
    if (selection == null) {
      return null;
    }
    return _MobileAlignMenu(
      editorState: editorState,
      selection: selection,
    );
  },
);

class _MobileAlignMenu extends StatelessWidget {
  const _MobileAlignMenu({
    required this.editorState,
    required this.selection,
  });

  final Selection selection;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3,
      shrinkWrap: true,
      children: [
        _buildAlignmentButton(
          context,
          'left',
          LocaleKeys.document_plugins_optionAction_left.tr(),
        ),
        _buildAlignmentButton(
          context,
          'center',
          LocaleKeys.document_plugins_optionAction_center.tr(),
        ),
        _buildAlignmentButton(
          context,
          'right',
          LocaleKeys.document_plugins_optionAction_right.tr(),
        ),
      ],
    );
  }

  Widget _buildAlignmentButton(
    BuildContext context,
    String alignment,
    String label,
  ) {
    final nodes = editorState.getNodesInSelection(selection);
    if (nodes.isEmpty) {
      const SizedBox.shrink();
    }

    bool isSatisfyCondition(bool Function(Object? value) test) {
      return nodes.every(
        (n) => test(n.attributes[blockComponentAlign]),
      );
    }

    final data = switch (alignment) {
      'left' => FlowySvgs.toolbar_align_left_s,
      'center' => FlowySvgs.toolbar_align_center_s,
      'right' => FlowySvgs.toolbar_align_right_s,
      _ => throw UnimplementedError(),
    };
    final isSelected = isSatisfyCondition((value) => value == alignment);

    return MobileToolbarItemMenuBtn(
      icon: FlowySvg(data, size: const Size.square(28)),
      label: FlowyText(label),
      isSelected: isSelected,
      onPressed: () async {
        await editorState.updateNode(
          selection,
          (node) => node.copyWith(
            attributes: {
              ...node.attributes,
              blockComponentAlign: alignment,
            },
          ),
        );
      },
    );
  }
}
