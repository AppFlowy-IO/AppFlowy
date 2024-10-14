import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ToggleListBlockKeys {
  const ToggleListBlockKeys._();

  static const String type = 'toggle_list';

  /// The content of a code block.
  ///
  /// The value is a String.
  static const String delta = blockComponentDelta;

  static const String backgroundColor = blockComponentBackgroundColor;

  static const String textDirection = blockComponentTextDirection;

  /// The value is a bool.
  static const String collapsed = 'collapsed';
}

Node toggleListBlockNode({
  String? text,
  Delta? delta,
  bool collapsed = false,
  String? textDirection,
  Attributes? attributes,
  Iterable<Node>? children,
}) {
  return Node(
    type: ToggleListBlockKeys.type,
    attributes: {
      ToggleListBlockKeys.collapsed: collapsed,
      ToggleListBlockKeys.delta:
          (delta ?? (Delta()..insert(text ?? ''))).toJson(),
      if (attributes != null) ...attributes,
      if (textDirection != null)
        ToggleListBlockKeys.textDirection: textDirection,
    },
    children: children ?? [],
  );
}

// defining the toggle list block menu item
SelectionMenuItem toggleListBlockItem = SelectionMenuItem.node(
  getName: LocaleKeys.document_plugins_toggleList.tr,
  iconData: Icons.arrow_right,
  keywords: ['collapsed list', 'toggle list', 'list'],
  nodeBuilder: (editorState, _) => toggleListBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

class ToggleListBlockComponentBuilder extends BlockComponentBuilder {
  ToggleListBlockComponentBuilder({
    super.configuration,
    this.padding = const EdgeInsets.all(0),
  });

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
  BlockComponentValidate get validate => (node) => node.delta != null;
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
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentBackgroundColorMixin,
        NestedBlockComponentStatefulWidgetMixin,
        BlockComponentTextDirectionMixin,
        BlockComponentAlignMixin {
  // the key used to forward focus to the richtext child
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: ToggleListBlockKeys.type,
  );

  @override
  Node get node => widget.node;

  @override
  EdgeInsets get indentPadding => configuration.indentPadding(
        node,
        calculateTextDirection(
          layoutDirection: Directionality.maybeOf(context),
        ),
      );

  bool get collapsed => node.attributes[ToggleListBlockKeys.collapsed] ?? false;

  @override
  Widget build(BuildContext context) {
    return collapsed
        ? buildComponent(context)
        : buildComponentWithChildren(context);
  }

  @override
  Widget buildComponent(
    BuildContext context, {
    bool withBackgroundColor = false,
  }) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    Widget child = Container(
      color: backgroundColor,
      width: double.infinity,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: textDirection,
        children: [
          // the emoji picker button for the note
          Container(
            constraints: const BoxConstraints(minWidth: 26, minHeight: 22),
            padding: const EdgeInsets.only(right: 4.0),
            child: AnimatedRotation(
              turns: collapsed ? 0.0 : 0.25,
              duration: const Duration(milliseconds: 200),
              child: FlowyIconButton(
                width: 18.0,
                icon: const Icon(
                  Icons.arrow_right,
                  size: 18.0,
                ),
                onPressed: onCollapsed,
              ),
            ),
          ),

          Flexible(
            child: AppFlowyRichText(
              key: forwardKey,
              delegate: this,
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
              textDirection: textDirection,
              textAlign: alignment?.toTextAlign,
              cursorColor: editorState.editorStyle.cursorColor,
              selectionColor: editorState.editorStyle.selectionColor,
            ),
          ),
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
