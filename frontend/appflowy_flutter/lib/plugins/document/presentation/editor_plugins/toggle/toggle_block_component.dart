import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ToggleListBlockKeys {
  const ToggleListBlockKeys._();

  static const String type = 'toggle_list';

  /// The content of a code block.
  ///
  /// The value is a String.
  static const String delta = 'delta';

  /// The value is a bool.
  static const String collapsed = 'collapsed';
}

Node toggleListBlockNode({
  Delta? delta,
  bool collapsed = false,
}) {
  final attributes = {
    ToggleListBlockKeys.delta: (delta ?? Delta()).toJson(),
    ToggleListBlockKeys.collapsed: collapsed,
  };
  return Node(
    type: ToggleListBlockKeys.type,
    attributes: attributes,
    children: [paragraphNode()],
  );
}

class ToggleListBlockComponentBuilder extends BlockComponentBuilder {
  ToggleListBlockComponentBuilder({
    this.configuration = const BlockComponentConfiguration(),
    this.padding = const EdgeInsets.all(0),
  });

  @override
  final BlockComponentConfiguration configuration;

  final EdgeInsets padding;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return ToggleListBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      padding: padding,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) => node.delta != null;
}

class ToggleListBlockComponentWidget extends BlockComponentStatefulWidget {
  const ToggleListBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.padding = const EdgeInsets.all(0),
  });

  final EdgeInsets padding;

  @override
  State<ToggleListBlockComponentWidget> createState() =>
      _ToggleListBlockComponentWidgetState();
}

class _ToggleListBlockComponentWidgetState
    extends State<ToggleListBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectable,
        BlockComponentConfigurable,
        BackgroundColorMixin {
  // the key used to forward focus to the richtext child
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => node.key;

  @override
  Node get node => widget.node;

  bool get collapsed => node.attributes[ToggleListBlockKeys.collapsed] ?? false;

  late final editorState = context.read<EditorState>();

  @override
  Widget build(BuildContext context) {
    return collapsed
        ? buildToggleListBlockComponent(context)
        : buildToggleListBlockComponentWithChildren(context);
  }

  Widget buildToggleListBlockComponentWithChildren(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: NestedListWidget(
        children: editorState.renderer.buildList(
          context,
          widget.node.children,
        ),
        child: buildToggleListBlockComponent(context),
      ),
    );
  }

  // build the richtext child
  Widget buildToggleListBlockComponent(BuildContext context) {
    Widget child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // the emoji picker button for the note
        FlowyIconButton(
          width: 24.0,
          icon: Icon(
            collapsed ? Icons.arrow_right : Icons.arrow_drop_down,
          ),
          onPressed: onCollapsed,
        ),
        const SizedBox(
          width: 4.0,
        ),
        Expanded(
          child: FlowyRichText(
            key: forwardKey,
            node: widget.node,
            editorState: editorState,
            placeholderText: placeholderText,
            lineHeight: 1.5,
            textSpanDecorator: (textSpan) => textSpan.updateTextStyle(
              textStyle,
            ),
            placeholderTextSpanDecorator: (textSpan) =>
                textSpan.updateTextStyle(
              placeholderTextStyle,
            ),
          ),
        ),
      ],
    );

    if (widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }

  Future<void> onCollapsed() async {
    final transaction = editorState.transaction
      ..updateNode(node, {
        ToggleListBlockKeys.collapsed: !collapsed,
      });
    await editorState.apply(transaction);
  }
}
