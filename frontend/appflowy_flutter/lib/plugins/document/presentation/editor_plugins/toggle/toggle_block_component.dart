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
  name: LocaleKeys.document_plugins_toggleList.tr(),
  iconData: Icons.arrow_right,
  keywords: ['collapsed list', 'toggle list', 'list'],
  nodeBuilder: (editorState) => toggleListBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

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
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentBackgroundColorMixin,
        NestedBlockComponentStatefulWidgetMixin,
        BlockComponentTextDirectionMixin {
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
          defaultTextDirection: Directionality.maybeOf(context),
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
  Widget buildComponent(BuildContext context) {
    final textDirection = calculateTextDirection(
      defaultTextDirection: Directionality.maybeOf(context),
    );

    Widget child = Container(
      color: backgroundColor,
      width: double.infinity,
      child: Row(
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
            child: AppFlowyRichText(
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
              textDirection: textDirection,
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
