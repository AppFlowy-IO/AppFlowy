import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OutlineBlockKeys {
  const OutlineBlockKeys._();

  static const String type = 'outline';
}

// defining the callout block menu item for selection
SelectionMenuItem outlineItem = SelectionMenuItem.node(
  name: LocaleKeys.document_plugins_outline.tr(),
  iconData: Icons.list_alt,
  keywords: ['outline', 'table of contents'],
  nodeBuilder: (editorState) => outlineBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

Node outlineBlockNode() {
  return Node(
    type: OutlineBlockKeys.type,
  );
}

class OutlineBlockComponentBuilder extends BlockComponentBuilder {
  OutlineBlockComponentBuilder({
    this.configuration = const BlockComponentConfiguration(),
  });

  @override
  final BlockComponentConfiguration configuration;

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
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  late EditorState editorState = context.read<EditorState>();
  late Stream<Transaction> stream = editorState.transactionStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (widget.showActions && widget.actionBuilder != null) {
          return BlockComponentActionWrapper(
            node: widget.node,
            actionBuilder: widget.actionBuilder!,
            child: _buildOutlineBlock(),
          );
        }
        return _buildOutlineBlock();
      },
    );
  }

  Widget _buildOutlineBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15.0,
        vertical: 20.0,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.document_plugins_outline_heading.tr(),
            style: editorState.editorStyle.textStyleConfiguration.text,
          ),
          const Divider(
            color: Colors.white54,
          ),
          ...getHeadingNodes().map((e) => OutlineItemWidget(node: e)).toList(),
        ],
      ),
    );
  }

  Iterable<Node> getHeadingNodes() {
    final children = editorState.document.root.children;
    return children.where((element) => element.type == HeadingBlockKeys.type);
  }
}

class OutlineItemWidget extends StatelessWidget {
  OutlineItemWidget({
    super.key,
    required this.node,
  }) {
    assert(node.type == HeadingBlockKeys.type);
  }

  final Node node;

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // when clicked scroll the view to the heading
          editorState.updateSelectionWithReason(
            Selection.single(
              path: node.path,
              startOffset: node.delta?.length ?? 0,
            ),
            reason: SelectionUpdateReason.uiEvent,
          );
        },
        child: Container(
          margin: EdgeInsets.only(top: node.verticalSpacing),
          padding: EdgeInsets.only(left: node.leftIndent),
          child: Text(
            node.outlineItemText,
            style: editorState.editorStyle.textStyleConfiguration.text,
          ),
        ),
      ),
    );
  }
}

extension on Node {
  double get verticalSpacing {
    if (type != HeadingBlockKeys.type) {
      assert(false);
      return 0.0;
    }
    final level = attributes[HeadingBlockKeys.level];
    if (level == 1) {
      return 10;
    } else if (level == 2) {
      return 8;
    }
    return 5;
  }

  double get leftIndent {
    if (type != HeadingBlockKeys.type) {
      assert(false);
      return 0.0;
    }
    final level = attributes[HeadingBlockKeys.level];
    if (level == 2) {
      return 15;
    } else if (level == 3) {
      return 60;
    }
    return 0;
  }

  String get outlineItemText {
    if (type != HeadingBlockKeys.type) {
      assert(false);
      return '';
    }
    final delta = this.delta;
    if (delta == null) {
      return '';
    }
    final text = delta.toPlainText();
    final level = attributes[HeadingBlockKeys.level];
    if (level == 2) {
      return '∘ $text';
    } else if (level == 3) {
      return '- $text';
    }
    return text;
  }
}
