import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OutlineBlockKeys {
  const OutlineBlockKeys._();

  static const String type = 'outline';
  static const String backgroundColor = blockComponentBackgroundColor;
}

// defining the callout block menu item for selection
SelectionMenuItem outlineItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_selectionMenu_outline.tr(),
  iconData: Icons.list_alt,
  keywords: ['outline', 'table of contents'],
  nodeBuilder: (editorState, _) => outlineBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

Node outlineBlockNode() {
  return Node(
    type: OutlineBlockKeys.type,
  );
}

class OutlineBlockComponentBuilder extends BlockComponentBuilder {
  OutlineBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return OutlineBlockWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) => node.children.isEmpty;
}

class OutlineBlockWidget extends BlockComponentStatefulWidget {
  const OutlineBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<OutlineBlockWidget> createState() => _OutlineBlockWidgetState();
}

class _OutlineBlockWidgetState extends State<OutlineBlockWidget>
    with
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin,
        BlockComponentBackgroundColorMixin {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  late EditorState editorState = context.read<EditorState>();
  late Stream<(TransactionTime, Transaction)> stream =
      editorState.transactionStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        Widget child = _buildOutlineBlock();

        if (PlatformExtension.isDesktopOrWeb) {
          if (widget.showActions && widget.actionBuilder != null) {
            child = BlockComponentActionWrapper(
              node: widget.node,
              actionBuilder: widget.actionBuilder!,
              child: child,
            );
          }
        } else {
          child = MobileBlockActionButtons(
            node: node,
            editorState: editorState,
            child: child,
          );
        }

        return child;
      },
    );
  }

  Widget _buildOutlineBlock() {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    final children = getHeadingNodes()
        .map(
          (e) => Container(
            padding: const EdgeInsets.only(
              bottom: 4.0,
            ),
            width: double.infinity,
            child: OutlineItemWidget(
              node: e,
              textDirection: textDirection,
            ),
          ),
        )
        .toList();

    final child = children.isEmpty
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              LocaleKeys.document_plugins_outline_addHeadingToCreateOutline
                  .tr(),
              style: configuration.placeholderTextStyle(node),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              color: backgroundColor,
            ),
            child: Column(
              key: ValueKey(children.hashCode),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              textDirection: textDirection,
              children: children,
            ),
          );

    return Container(
      constraints: const BoxConstraints(
        minHeight: 40.0,
      ),
      padding: padding,
      child: child,
    );
  }

  Iterable<Node> getHeadingNodes() {
    final children = editorState.document.root.children;
    return children.where(
      (element) =>
          element.type == HeadingBlockKeys.type &&
          element.delta?.isNotEmpty == true,
    );
  }
}

class OutlineItemWidget extends StatelessWidget {
  OutlineItemWidget({
    super.key,
    required this.node,
    required this.textDirection,
  }) {
    assert(node.type == HeadingBlockKeys.type);
  }

  final Node node;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();
    final textStyle = editorState.editorStyle.textStyleConfiguration;
    final style = textStyle.href.combine(textStyle.text);
    return FlowyHover(
      style: HoverStyle(
        hoverColor: Theme.of(context).hoverColor,
      ),
      builder: (context, onHover) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => scrollToBlock(context),
          child: Row(
            textDirection: textDirection,
            children: [
              HSpace(node.leftIndent),
              Text(
                node.outlineItemText,
                textDirection: textDirection,
                style: style.copyWith(
                  color: onHover
                      ? Theme.of(context).colorScheme.onSecondary
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void scrollToBlock(BuildContext context) {
    final editorState = context.read<EditorState>();
    final editorScrollController = context.read<EditorScrollController>();
    editorScrollController.itemScrollController.jumpTo(
      index: node.path.first,
      alignment: 0.5,
    );
    editorState.selection = Selection.collapsed(
      Position(path: node.path, offset: node.delta?.length ?? 0),
    );
  }
}

extension on Node {
  double get leftIndent {
    assert(type == HeadingBlockKeys.type);
    if (type != HeadingBlockKeys.type) {
      return 0.0;
    }
    final level = attributes[HeadingBlockKeys.level];
    if (level == 2) {
      return 20;
    } else if (level == 3) {
      return 40;
    }
    return 0;
  }

  String get outlineItemText {
    return delta?.toPlainText() ?? '';
  }
}
