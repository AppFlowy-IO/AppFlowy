import 'package:appflowy/generated/locale_keys.g.dart' show LocaleKeys;
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

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

  /// the type of [FlowyIconType]
  static const String iconType = 'icon_type';
}

// The one is inserted through selection menu
Node calloutNode({
  Delta? delta,
  EmojiIconData? emoji,
  Color? defaultColor,
}) {
  final defaultEmoji = emoji ?? EmojiIconData.emoji('📌');
  final attributes = {
    CalloutBlockKeys.delta: (delta ?? Delta()).toJson(),
    CalloutBlockKeys.icon: defaultEmoji.emoji,
    CalloutBlockKeys.iconType: defaultEmoji.type,
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
      calloutNode(defaultColor: Colors.transparent),
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
    required this.inlinePadding,
  });

  final Color defaultColor;
  final EdgeInsets Function(Node node) inlinePadding;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CalloutBlockComponentWidget(
      key: node.key,
      node: node,
      defaultColor: defaultColor,
      inlinePadding: inlinePadding,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
      actionTrailingBuilder: (context, state) => actionTrailingBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  BlockComponentValidate get validate => (node) => node.delta != null;
}

// the main widget for rendering the callout block
class CalloutBlockComponentWidget extends BlockComponentStatefulWidget {
  const CalloutBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
    required this.defaultColor,
    required this.inlinePadding,
  });

  final Color defaultColor;
  final EdgeInsets Function(Node node) inlinePadding;

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
        BlockComponentBackgroundColorMixin,
        NestedBlockComponentStatefulWidgetMixin {
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
  EmojiIconData get emoji {
    final icon = node.attributes[CalloutBlockKeys.icon];
    final type =
        node.attributes[CalloutBlockKeys.iconType] ?? FlowyIconType.emoji;
    EmojiIconData result = EmojiIconData.emoji('📌');
    try {
      result = EmojiIconData(FlowyIconType.values.byName(type), icon);
    } catch (e) {
      Log.info(
        'get emoji error with icon:[$icon], type:[$type] within calloutBlockComponentWidget',
        e,
      );
    }
    return result;
  }

  @override
  Widget buildComponentWithChildren(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          left: cachedLeft,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(6.0)),
              color: backgroundColor,
            ),
          ),
        ),
        NestedListWidget(
          indentPadding: indentPadding.copyWith(bottom: 8),
          child: buildComponent(context, withBackgroundColor: false),
          children: editorState.renderer.buildList(
            context,
            widget.node.children,
          ),
        ),
      ],
    );
  }

  // build the callout block widget
  @override
  Widget buildComponent(
    BuildContext context, {
    bool withBackgroundColor = true,
  }) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );
    final (emojiSize, emojiButtonSize) = calculateEmojiSize();
    final documentId = context.read<DocumentBloc?>()?.documentId;
    Widget child = Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
        color: withBackgroundColor ? backgroundColor : null,
      ),
      padding: widget.inlinePadding(widget.node),
      width: double.infinity,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: textDirection,
        children: [
          const HSpace(6.0),
          // the emoji picker button for the note
          EmojiPickerButton(
            // force to refresh the popover state
            key: ValueKey(widget.node.id + emoji.emoji),
            enable: editorState.editable,
            title: '',
            margin: UniversalPlatform.isMobile
                ? const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0)
                : EdgeInsets.zero,
            emoji: emoji,
            emojiSize: emojiSize,
            showBorder: false,
            buttonSize: emojiButtonSize,
            documentId: documentId,
            tabs: const [
              PickerTabType.emoji,
              PickerTabType.icon,
              PickerTabType.custom,
            ],
            onSubmitted: (r, controller) {
              setEmojiIconData(r.data);
              if (!r.keepOpen) controller?.close();
            },
          ),
          if (UniversalPlatform.isDesktopOrWeb) const HSpace(6.0),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: buildCalloutBlockComponent(context, textDirection),
            ),
          ),
          const HSpace(8.0),
        ],
      ),
    );

    child = Padding(
      key: blockComponentKey,
      padding: EdgeInsets.zero,
      child: child,
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      blockColor: editorState.editorStyle.selectionColor,
      selectionAboveBlock: true,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: widget.node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
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
    return AppFlowyRichText(
      key: forwardKey,
      delegate: this,
      node: widget.node,
      editorState: editorState,
      placeholderText: placeholderText,
      textAlign: alignment?.toTextAlign ?? textAlign,
      textSpanDecorator: (textSpan) => textSpan.updateTextStyle(
        textStyleWithTextSpan(textSpan: textSpan),
      ),
      placeholderTextSpanDecorator: (textSpan) => textSpan.updateTextStyle(
        placeholderTextStyleWithTextSpan(textSpan: textSpan),
      ),
      textDirection: textDirection,
      cursorColor: editorState.editorStyle.cursorColor,
      selectionColor: editorState.editorStyle.selectionColor,
    );
  }

  // set the emoji of the note block
  Future<void> setEmojiIconData(EmojiIconData data) async {
    final transaction = editorState.transaction
      ..updateNode(node, {
        CalloutBlockKeys.icon: data.emoji,
        CalloutBlockKeys.iconType: data.type.name,
      })
      ..afterSelection = Selection.collapsed(
        Position(path: node.path, offset: node.delta?.length ?? 0),
      );
    await editorState.apply(transaction);
  }

  (double, Size) calculateEmojiSize() {
    const double defaultEmojiSize = 16.0;
    const Size defaultEmojiButtonSize = Size(30.0, 30.0);
    final double emojiSize =
        editorState.editorStyle.textStyleConfiguration.text.fontSize ??
            defaultEmojiSize;
    final emojiButtonSize =
        defaultEmojiButtonSize * emojiSize / defaultEmojiSize;
    return (emojiSize, emojiButtonSize);
  }
}
