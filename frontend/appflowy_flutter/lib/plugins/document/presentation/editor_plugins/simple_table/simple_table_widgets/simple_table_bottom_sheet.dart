import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

// Note: This widget is only used for mobile.
class SimpleTableBottomSheet extends StatelessWidget {
  const SimpleTableBottomSheet({
    super.key,
    required this.type,
    required this.node,
  });

  final SimpleTableMoreActionType type;
  final Node node;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // copy, cut, paste, delete
        const SimpleTableQuickActions(),
        const VSpace(12),
        // insert row, insert column
        SimpleTableInsertActions(type: type),
      ],
    );
  }
}

/// A quick action for the table.
///
/// Copy, Cut, Paste, Delete
enum SimpleTableQuickActionType {
  copy,
  cut,
  paste,
  delete;

  FlowySvgData get icon => switch (this) {
        copy => FlowySvgs.m_table_quick_action_copy_s,
        cut => FlowySvgs.m_table_quick_action_cut_s,
        paste => FlowySvgs.m_table_quick_action_paste_s,
        delete => FlowySvgs.m_table_quick_action_delete_s,
      };

  // todo: i18n
  String get name => switch (this) {
        copy => 'Copy',
        cut => 'Cut',
        paste => 'Paste',
        delete => 'Delete',
      };
}

class SimpleTableQuickActions extends StatelessWidget {
  const SimpleTableQuickActions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: SimpleTableConstants.actionSheetQuickActionSectionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SimpleTableQuickAction(type: SimpleTableQuickActionType.cut),
          SimpleTableQuickAction(type: SimpleTableQuickActionType.copy),
          SimpleTableQuickAction(type: SimpleTableQuickActionType.paste),
          SimpleTableQuickAction(type: SimpleTableQuickActionType.delete),
        ],
      ),
    );
  }
}

class SimpleTableQuickAction extends StatelessWidget {
  const SimpleTableQuickAction({
    super.key,
    required this.type,
  });

  final SimpleTableQuickActionType type;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedGestureDetector(
        child: FlowySvg(
          type.icon,
          blendMode: null,
        ),
        onTapUp: () {},
      ),
    );
  }
}

class SimpleTableInsertActions extends StatelessWidget {
  const SimpleTableInsertActions({
    super.key,
    required this.type,
  });

  final SimpleTableMoreActionType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: SimpleTableConstants.actionSheetInsertSectionHeight,
      child: switch (type) {
        SimpleTableMoreActionType.row => const Row(
            children: [
              SimpleTableInsertAction(
                type: SimpleTableMoreAction.insertAbove,
                enableLeftBorder: true,
              ),
              HSpace(2),
              SimpleTableInsertAction(
                type: SimpleTableMoreAction.insertBelow,
                enableRightBorder: true,
              ),
            ],
          ),
        SimpleTableMoreActionType.column => const Row(
            children: [
              SimpleTableInsertAction(
                type: SimpleTableMoreAction.insertLeft,
                enableLeftBorder: true,
              ),
              HSpace(2),
              SimpleTableInsertAction(
                type: SimpleTableMoreAction.insertRight,
                enableRightBorder: true,
              ),
            ],
          ),
      },
    );
  }
}

class SimpleTableInsertAction extends StatelessWidget {
  const SimpleTableInsertAction({
    super.key,
    required this.type,
    this.enableLeftBorder = false,
    this.enableRightBorder = false,
  });

  final SimpleTableMoreAction type;
  final bool enableLeftBorder;
  final bool enableRightBorder;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          // todo: replace with theme color
          color: Colors.red,
          shape: _buildBorder(),
        ),
        child: AnimatedGestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlowySvg(type.leftIconSvg, size: const Size.square(24)),
              FlowyText(
                type.name,
                fontSize: 12,
                figmaLineHeight: 16,
              ),
            ],
          ),
          onTapUp: () {},
        ),
      ),
    );
  }

  RoundedRectangleBorder _buildBorder() {
    if (enableLeftBorder) {
      return const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      );
    } else if (enableRightBorder) {
      return const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      );
    }
    return const RoundedRectangleBorder();
  }
}
