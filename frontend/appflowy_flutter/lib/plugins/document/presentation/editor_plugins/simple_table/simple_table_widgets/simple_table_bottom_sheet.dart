import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';

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
    return const Column(
      children: [
        SimpleTableQuickActions(),
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
  String get i18n => switch (this) {
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
    return SizedBox(
      height: SimpleTableConstants.actionSheetInsertSectionHeight,
      child: switch (type) {
        SimpleTableMoreActionType.row => Row(
            children: [
              SimpleTableInsertAction(type: SimpleTableMoreAction.insertAbove),
              SimpleTableInsertAction(type: SimpleTableMoreAction.insertBelow),
            ],
          ),
        SimpleTableMoreActionType.column => Row(
            children: [
              SimpleTableInsertAction(type: SimpleTableMoreAction.insertLeft),
              SimpleTableInsertAction(type: SimpleTableMoreAction.insertRight),
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
  });

  final SimpleTableMoreAction type;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedGestureDetector(
        child: Column(
          children: [
            FlowySvg(type.icon),
            Text(type.i18n),
          ],
        ),
        onTapUp: () {},
      ),
    );
  }
}
