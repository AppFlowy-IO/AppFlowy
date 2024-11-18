import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class OutlineBlockKeys {
  const OutlineBlockKeys._();

  static const String type = 'outline';
  static const String backgroundColor = blockComponentBackgroundColor;
  static const String depth = 'depth';
}

Node outlineBlockNode() {
  return Node(
    type: OutlineBlockKeys.type,
  );
}

enum _OutlineBlockStatus {
  noHeadings,
  noMatchHeadings,
  success;
}

final _availableBlockTypes = [
  HeadingBlockKeys.type,
  ToggleListBlockKeys.type,
];

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
  BlockComponentValidate get validate => (node) => node.children.isEmpty;
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
  // Change the value if the heading block type supports heading levels greater than '3'
  static const maxVisibleDepth = 6;

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

        if (UniversalPlatform.isDesktopOrWeb) {
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
    final (status, headings) = getHeadingNodes();

    Widget child;

    switch (status) {
      case _OutlineBlockStatus.noHeadings:
        child = Align(
          alignment: Alignment.centerLeft,
          child: Text(
            LocaleKeys.document_plugins_outline_addHeadingToCreateOutline.tr(),
            style: configuration.placeholderTextStyle(node),
          ),
        );
      case _OutlineBlockStatus.noMatchHeadings:
        child = Align(
          alignment: Alignment.centerLeft,
          child: Text(
            LocaleKeys.document_plugins_outline_noMatchHeadings.tr(),
            style: configuration.placeholderTextStyle(node),
          ),
        );
      case _OutlineBlockStatus.success:
        final children = headings
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
        child = Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Column(
            children: children,
          ),
        );
    }

    return Container(
      constraints: const BoxConstraints(
        minHeight: 40.0,
      ),
      padding: padding,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 2.0,
          horizontal: 5.0,
        ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          color: backgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          textDirection: textDirection,
          children: [
            Text(
              LocaleKeys.document_outlineBlock_placeholder.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const VSpace(8.0),
            child,
          ],
        ),
      ),
    );
  }

  (_OutlineBlockStatus, Iterable<Node>) getHeadingNodes() {
    final children = editorState.document.root.children;
    final int level =
        node.attributes[OutlineBlockKeys.depth] ?? maxVisibleDepth;
    var headings = children.where(
      (e) => _isHeadingNode(e),
    );
    if (headings.isEmpty) {
      return (_OutlineBlockStatus.noHeadings, []);
    }
    headings = headings.where(
      (e) =>
          (e.type == HeadingBlockKeys.type &&
              e.attributes[HeadingBlockKeys.level] <= level) ||
          (e.type == ToggleListBlockKeys.type &&
              e.attributes[ToggleListBlockKeys.level] <= level),
    );
    if (headings.isEmpty) {
      return (_OutlineBlockStatus.noMatchHeadings, []);
    }
    return (_OutlineBlockStatus.success, headings);
  }

  bool _isHeadingNode(Node node) {
    if (node.type == HeadingBlockKeys.type && node.delta?.isNotEmpty == true) {
      return true;
    }

    if (node.type == ToggleListBlockKeys.type &&
        node.delta?.isNotEmpty == true &&
        node.attributes[ToggleListBlockKeys.level] != null) {
      return true;
    }

    return false;
  }
}

class OutlineItemWidget extends StatelessWidget {
  OutlineItemWidget({
    super.key,
    required this.node,
    required this.textDirection,
  }) {
    assert(_availableBlockTypes.contains(node.type));
  }

  final Node node;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();
    final textStyle = editorState.editorStyle.textStyleConfiguration;
    final style = textStyle.href.combine(textStyle.text);
    return FlowyButton(
      onTap: () => scrollToBlock(context),
      text: Row(
        textDirection: textDirection,
        children: [
          HSpace(node.leftIndent),
          Text(
            node.outlineItemText,
            textDirection: textDirection,
            style: style,
          ),
        ],
      ),
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
    assert(_availableBlockTypes.contains(type));

    if (!_availableBlockTypes.contains(type)) {
      return 0.0;
    }

    final level = attributes[HeadingBlockKeys.level] ??
        attributes[ToggleListBlockKeys.level];
    if (level != null) {
      final indent = (level - 1) * 15.0;
      return indent;
    }

    return 0.0;
  }

  String get outlineItemText {
    return delta?.toPlainText() ?? '';
  }
}
