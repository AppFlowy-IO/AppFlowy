import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum OptionDepthType {
  h1(1, 'H1'),
  h2(2, 'H2'),
  h3(3, 'H3'),
  h4(4, 'H4'),
  h5(5, 'H5'),
  h6(6, 'H6');

  const OptionDepthType(this.level, this.description);

  final String description;
  final int level;

  static OptionDepthType fromLevel(int? level) {
    switch (level) {
      case 1:
        return OptionDepthType.h1;
      case 2:
        return OptionDepthType.h2;
      case 3:
      default:
        return OptionDepthType.h3;
    }
  }
}

class DepthOptionAction extends PopoverActionCell {
  DepthOptionAction({required this.editorState});

  final EditorState editorState;

  @override
  Widget? leftIcon(Color iconColor) {
    return FlowySvg(
      OptionAction.depth.svg,
      size: const Size.square(16),
    );
  }

  @override
  String get name => LocaleKeys.document_plugins_optionAction_depth.tr();

  @override
  PopoverActionCellBuilder get builder =>
      (context, parentController, controller) {
        final children = buildDepthOptions(context, (depth) async {
          await onDepthChanged(depth);
          controller.close();
          parentController.close();
        });

        return SizedBox(
          width: 42,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      };

  List<Widget> buildDepthOptions(
    BuildContext context,
    Future<void> Function(OptionDepthType) onTap,
  ) {
    return OptionDepthType.values
        .map((e) => OptionDepthWrapper(e))
        .map(
          (e) => HoverButton(
            onTap: () => onTap(e.inner),
            itemHeight: ActionListSizes.itemHeight,
            name: e.name,
          ),
        )
        .toList();
  }

  OptionDepthType depth(Node node) {
    final level = node.attributes[OutlineBlockKeys.depth];
    return OptionDepthType.fromLevel(level);
  }

  Future<void> onDepthChanged(OptionDepthType depth) async {
    final selection = editorState.selection;
    final node = selection != null
        ? editorState.getNodeAtPath(selection.start.path)
        : null;

    if (node == null || depth == this.depth(node)) return;

    final transaction = editorState.transaction;
    transaction.updateNode(
      node,
      {OutlineBlockKeys.depth: depth.level},
    );
    await editorState.apply(transaction);
  }
}

class OptionDepthWrapper extends ActionCell {
  OptionDepthWrapper(this.inner);

  final OptionDepthType inner;

  @override
  String get name => inner.description;
}

class OptionActionWrapper extends ActionCell {
  OptionActionWrapper(this.inner);

  final OptionAction inner;

  @override
  Widget? leftIcon(Color iconColor) => FlowySvg(inner.svg);

  @override
  String get name => inner.description;
}
