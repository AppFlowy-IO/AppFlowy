import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
  name: LocaleKeys.document_selectionMenu_outline.tr(),
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

  // get the background color of the note block from the node's attributes
  Color get backgroundColor {
    final colorString =
        node.attributes[OutlineBlockKeys.backgroundColor] as String?;
    if (colorString == null) {
      return Colors.transparent;
    }
    return colorString.toColor();
  }

  late EditorState editorState = context.read<EditorState>();
  late Stream<(TransactionTime, Transaction)> stream =
      editorState.transactionStream;

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
    final children = getHeadingNodes()
        .map(
          (e) => Container(
            padding: const EdgeInsets.only(
              bottom: 4.0,
            ),
            width: double.infinity,
            child: OutlineItemWidget(node: e),
          ),
        )
        .toList();
    if (children.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          LocaleKeys.document_plugins_outline_addHeadingToCreateOutline.tr(),
          style: configuration.placeholderTextStyle(node),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: children,
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
    final textStyle = editorState.editorStyle.textStyleConfiguration;
    final style = textStyle.href.combine(textStyle.text);
    return FlowyHover(
      style: HoverStyle(
        hoverColor: Theme.of(context).hoverColor,
      ),
      child: GestureDetector(
        onTap: () => updateBlockSelection(context),
        child: Container(
          padding: EdgeInsets.only(left: node.leftIndent),
          child: Text(
            node.outlineItemText,
            style: style,
          ),
        ),
      ),
    );
  }

  void updateBlockSelection(BuildContext context) async {
    final editorState = context.read<EditorState>();
    editorState.selectionType = SelectionType.block;
    editorState.selection = Selection.collapse(
      node.path,
      node.delta?.length ?? 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      editorState.selectionType = null;
    });
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
