import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OutlineBlockKeys {
  const OutlineBlockKeys._();

  static const String type = 'outline_block';
}

// defining the callout block menu item for selection
SelectionMenuItem outlineItem = SelectionMenuItem.node(
  name: 'Outline',
  iconData: Icons.clear_all,
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
  bool validate(Node node) => true;
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

  List<Node> _headings = [];

  late StreamSubscription transactionSubscription;

  @override
  void initState() {
    super.initState();
    getHeadings();

    transactionSubscription =
        context.read<EditorState>().transactionStream.listen((event) {
      // Listen to document changes and update outline accordingly
      getHeadings();
    });
  }

  @override
  void dispose() {
    transactionSubscription.cancel();
    super.dispose();
  }

  void getHeadings() {
    final data = context.read<EditorState>();

    final List<Node> children = data.document.root.children.toList();

    final List<Node> newHeadingList = [];
    for (final Node e in children) {
      if (e.type == "heading") {
        newHeadingList.add(e);
      }
    }

    _headings = newHeadingList;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlockComponentActionWrapper(
      node: widget.node,
      actionBuilder: widget.actionBuilder!,
      child: StreamBuilder(
        stream: context.read<EditorState>().transactionStream,
        builder: (context, snapshot) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TABLE OF CONTENTS: ",
                  style: context
                      .read<EditorState>()
                      .editorStyle
                      .textStyleConfiguration
                      .text,
                ),
                const Divider(
                  color: Colors.white54,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _headings.map(
                    (e) {
                      return OutlineItemWidget(
                        text: getHeadingText(e),
                        headingLevel: getHeadingLevel(e),
                        node: e,
                      );
                    },
                  ).toList(),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  int getHeadingLevel(Node node) {
    return node.attributes["level"] as int;
  }

  String getHeadingText(Node node) {
    try {
      return node.attributes["delta"][0]["insert"] as String;
    } catch (e) {
      return "";
    }
  }
}

class OutlineItemWidget extends StatelessWidget {
  final String text;
  final int headingLevel;
  final Node node;
  const OutlineItemWidget({
    super.key,
    required this.text,
    required this.headingLevel,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // when clicked scroll the view to the heading
          context.read<EditorState>().updateSelectionWithReason(
                Selection.single(path: node.path, startOffset: 0),
                reason: SelectionUpdateReason.uiEvent,
              );
        },
        child: Container(
          margin: EdgeInsets.only(top: getVerticalSpacing()),
          padding: EdgeInsets.only(left: getLeftIndent()),
          child: Text(
            getOutlineItemText(),
            style: context
                .read<EditorState>()
                .editorStyle
                .textStyleConfiguration
                .text,
          ),
        ),
      ),
    );
  }

  double getVerticalSpacing() {
    if (headingLevel == 1) return 10;
    if (headingLevel == 2) return 8;

    return 5;
  }

  double getLeftIndent() {
    if (headingLevel == 2) return 15;
    if (headingLevel == 3) return 60;
    return 0;
  }

  String getOutlineItemText() {
    if (headingLevel == 2) return "∘ $text";
    if (headingLevel == 3) return "- $text";
    return text;
  }
}
