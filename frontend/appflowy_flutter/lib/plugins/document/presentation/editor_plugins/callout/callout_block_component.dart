import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/emoji_picker_button.dart';

// defining the keys of the callout block's attributes for easy access
class CalloutBlockKeys {
  const CalloutBlockKeys._();

  static const String type = 'callout';

  /// The content of a code block.
  ///
  /// The value is a String.
  static const String delta = 'delta';

  /// The background color of a callout block.
  ///
  /// The value is a String.
  static const String backgroundColor = blockComponentBackgroundColor;

  /// The emoji icon of a callout block.
  ///
  /// The value is a String.
  static const String icon = 'icon';
}

// creating a new callout node
Node calloutNode({
  Delta? delta,
  String emoji = '📌',
  String backgroundColor = '#F0F0F0',
}) {
  final attributes = {
    CalloutBlockKeys.delta: (delta ?? Delta()).toJson(),
    CalloutBlockKeys.icon: emoji,
    CalloutBlockKeys.backgroundColor: backgroundColor,
  };
  return Node(
    type: CalloutBlockKeys.type,
    attributes: attributes,
  );
}

// defining the callout block menu item for selection
SelectionMenuItem calloutItem = SelectionMenuItem.node(
  name: 'Callout',
  iconData: Icons.note,
  keywords: ['callout'],
  nodeBuilder: (editorState) => calloutNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  updateSelection: (_, path, __, ___) {
    return Selection.single(path: path, startOffset: 0);
  },
);

// building the callout block widget
class CalloutBlockComponentBuilder extends BlockComponentBuilder {
  CalloutBlockComponentBuilder({
    this.configuration = const BlockComponentConfiguration(),
  });

  @override
  final BlockComponentConfiguration configuration;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CalloutBlockComponentWidget(
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

  // validate the data of the node, if the result is false, the node will be rendered as a placeholder
  @override
  bool validate(Node node) =>
      node.delta != null &&
      node.children.isEmpty &&
      node.attributes[CalloutBlockKeys.icon] is String &&
      node.attributes[CalloutBlockKeys.backgroundColor] is String;
}

// the main widget for rendering the callout block
class CalloutBlockComponentWidget extends BlockComponentStatefulWidget {
  const CalloutBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<CalloutBlockComponentWidget> createState() =>
      _CalloutBlockComponentWidgetState();
}

class _CalloutBlockComponentWidgetState
    extends State<CalloutBlockComponentWidget>
    with SelectableMixin, DefaultSelectable, BlockComponentConfigurable {
  // the key used to forward focus to the richtext child
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  // the key used to identify this component
  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  // get the background color of the note block from the node's attributes
  Color get backgroundColor {
    final colorString =
        node.attributes[CalloutBlockKeys.backgroundColor] as String?;
    if (colorString == null) {
      return Colors.transparent;
    }
    return colorString.toColor();
  }

  // get the emoji of the note block from the node's attributes or default to '📌'
  String get emoji => node.attributes[CalloutBlockKeys.icon] ?? '📌';

  // get access to the editor state via provider
  late final editorState = Provider.of<EditorState>(context, listen: false);

  // build the callout block widget
  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: backgroundColor,
      ),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // the emoji picker button for the note
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: EmojiPickerButton(
              key: ValueKey(
                emoji.toString(),
              ), // force to refresh the popover state
              emoji: emoji,
              onSubmitted: (emoji, controller) {
                setEmoji(emoji.emoji);
                controller.close();
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: buildCalloutBlockComponent(context),
            ),
          ),
          const VSpace(10),
        ],
      ),
    );

    if (widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: widget.node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }

  // build the richtext child
  Widget buildCalloutBlockComponent(BuildContext context) {
    return Padding(
      padding: padding,
      child: FlowyRichText(
        key: forwardKey,
        node: widget.node,
        editorState: editorState,
        placeholderText: placeholderText,
        textSpanDecorator: (textSpan) => textSpan.updateTextStyle(
          textStyle,
        ),
        placeholderTextSpanDecorator: (textSpan) => textSpan.updateTextStyle(
          placeholderTextStyle,
        ),
      ),
    );
  }

  // set the emoji of the note block
  Future<void> setEmoji(String emoji) async {
    final transaction = editorState.transaction
      ..updateNode(node, {
        CalloutBlockKeys.icon: emoji,
      })
      ..afterSelection = Selection.collapse(
        node.path,
        node.delta?.length ?? 0,
      );
    await editorState.apply(transaction);
  }
}
