import 'package:appflowy/generated/locale_keys.g.dart' show LocaleKeys;
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra/theme_extension.dart';
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

// The one is inserted through selection menu
Node calloutNode({
  Delta? delta,
  String emoji = '📌',
  Color? defaultColor,
}) {
  final attributes = {
    CalloutBlockKeys.delta: (delta ?? Delta()).toJson(),
    CalloutBlockKeys.icon: emoji,
    CalloutBlockKeys.backgroundColor: defaultColor?.toHex(),
  };
  return Node(
    type: CalloutBlockKeys.type,
    attributes: attributes,
  );
}

// defining the callout block menu item in selection menu
SelectionMenuItem calloutItem = SelectionMenuItem.node(
  getName: LocaleKeys.document_plugins_callout.tr,
  iconData: Icons.note,
  keywords: [CalloutBlockKeys.type],
  nodeBuilder: (editorState, context) =>
      calloutNode(defaultColor: AFThemeExtension.of(context).calloutBGColor),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  updateSelection: (_, path, __, ___) {
    return Selection.single(path: path, startOffset: 0);
  },
);

// building the callout block widget
class CalloutBlockComponentBuilder extends BlockComponentBuilder {
  CalloutBlockComponentBuilder({
    super.configuration,
    required this.defaultColor,
  });

  final Color defaultColor;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CalloutBlockComponentWidget(
      key: node.key,
      node: node,
      defaultColor: defaultColor,
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
      node.attributes[CalloutBlockKeys.icon] is String;
}

// the main widget for rendering the callout block
class CalloutBlockComponentWidget extends BlockComponentStatefulWidget {
  const CalloutBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    required this.defaultColor,
  });

  final Color defaultColor;

  @override
  State<CalloutBlockComponentWidget> createState() =>
      _CalloutBlockComponentWidgetState();
}

class _CalloutBlockComponentWidgetState
    extends State<CalloutBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin,
        BlockComponentAlignMixin,
        BlockComponentBackgroundColorMixin {
  // the key used to forward focus to the richtext child
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  // the key used to identify this component
  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: CalloutBlockKeys.type,
  );

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  Color get backgroundColor {
    final color = super.backgroundColor;
    if (color == Colors.transparent) {
      return AFThemeExtension.of(context).calloutBGColor;
    }
    return color;
  }

  // get the emoji of the note block from the node's attributes or default to '📌'
  String get emoji {
    final icon = node.attributes[CalloutBlockKeys.icon];
    if (icon == null || icon.isEmpty) {
      return '📌';
    }
    return icon;
  }

  // get access to the editor state via provider
  @override
  late final editorState = Provider.of<EditorState>(context, listen: false);

  // build the callout block widget
  @override
  Widget build(BuildContext context) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    Widget child = Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: backgroundColor,
      ),
      width: double.infinity,
      alignment: alignment,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        textDirection: textDirection,
        children: [
          // the emoji picker button for the note
          Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              left: 4.0,
              right: 4.0,
            ),
            child: EmojiPickerButton(
              key: ValueKey(
                emoji.toString(),
              ), // force to refresh the popover state
              title: '',
              emoji: emoji,
              onSubmitted: (emoji, controller) {
                setEmoji(emoji);
                controller?.close();
              },
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: buildCalloutBlockComponent(context, textDirection),
            ),
          ),
          const HSpace(8.0),
        ],
      ),
    );

    child = Padding(
      key: blockComponentKey,
      padding: padding,
      child: child,
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: widget.node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }

  // build the richtext child
  Widget buildCalloutBlockComponent(
    BuildContext context,
    TextDirection textDirection,
  ) {
    return Padding(
      padding: padding,
      child: AppFlowyRichText(
        key: forwardKey,
        delegate: this,
        node: widget.node,
        editorState: editorState,
        placeholderText: placeholderText,
        textSpanDecorator: (textSpan) => textSpan.updateTextStyle(
          textStyle,
        ),
        placeholderTextSpanDecorator: (textSpan) => textSpan.updateTextStyle(
          placeholderTextStyle,
        ),
        textDirection: textDirection,
        cursorColor: editorState.editorStyle.cursorColor,
        selectionColor: editorState.editorStyle.selectionColor,
      ),
    );
  }

  // set the emoji of the note block
  Future<void> setEmoji(String emoji) async {
    final transaction = editorState.transaction
      ..updateNode(node, {
        CalloutBlockKeys.icon: emoji,
      })
      ..afterSelection = Selection.collapsed(
        Position(path: node.path, offset: node.delta?.length ?? 0),
      );
    await editorState.apply(transaction);
  }
}
