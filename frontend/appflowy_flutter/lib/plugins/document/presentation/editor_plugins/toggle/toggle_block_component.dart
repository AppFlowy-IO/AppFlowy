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

  /// The value is a int.
  ///
  /// If this value is not null, the block represent a toggle heading.
  static const String level = 'level';
}

Node toggleListBlockNode({
  String? text,
  Delta? delta,
  bool collapsed = false,
  String? textDirection,
  Attributes? attributes,
  Iterable<Node>? children,
}) {
  delta ??= (Delta()..insert(text ?? ''));
  return Node(
    type: ToggleListBlockKeys.type,
    children: children ?? [],
    attributes: {
      if (attributes != null) ...attributes,
      if (textDirection != null)
        ToggleListBlockKeys.textDirection: textDirection,
      ToggleListBlockKeys.collapsed: collapsed,
      ToggleListBlockKeys.delta: delta.toJson(),
    },
  );
}

Node toggleHeadingNode({
  int level = 1,
  String? text,
  Delta? delta,
  bool collapsed = false,
  String? textDirection,
  Attributes? attributes,
  Iterable<Node>? children,
}) {
  // only support level 1 - 6
  level = level.clamp(1, 6);
  return toggleListBlockNode(
    text: text,
    delta: delta,
    collapsed: collapsed,
    textDirection: textDirection,
    children: children,
    attributes: {
      if (attributes != null) ...attributes,
      ToggleListBlockKeys.level: level,
    },
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
    this.textStyleBuilder,
  });

  final EdgeInsets padding;

  /// The text style of the toggle heading block.
  final TextStyle Function(int level)? textStyleBuilder;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return ToggleListBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      padding: padding,
      textStyleBuilder: textStyleBuilder,
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
    this.textStyleBuilder,
  });

  final EdgeInsets padding;
  final TextStyle Function(int level)? textStyleBuilder;

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
  int? get level => node.attributes[ToggleListBlockKeys.level] as int?;

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
      color: withBackgroundColor || backgroundColor != Colors.transparent
          ? backgroundColor
          : null,
      width: double.infinity,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: textDirection,
        children: [
          _buildExpandIcon(),
          Flexible(
            child: _buildRichText(),
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

  Widget _buildRichText() {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );
    final level = node.attributes[ToggleListBlockKeys.level];
    return AppFlowyRichText(
      key: forwardKey,
      delegate: this,
      node: widget.node,
      editorState: editorState,
      placeholderText: placeholderText,
      lineHeight: 1.5,
      textSpanDecorator: (textSpan) {
        var result = textSpan.updateTextStyle(textStyle);
        if (level != null) {
          result = result.updateTextStyle(
            widget.textStyleBuilder?.call(level),
          );
        }
        return result;
      },
      placeholderTextSpanDecorator: (textSpan) {
        var result = textSpan.updateTextStyle(textStyle);
        if (level != null && widget.textStyleBuilder != null) {
          result = result.updateTextStyle(
            widget.textStyleBuilder?.call(level),
          );
        }
        return result.updateTextStyle(placeholderTextStyle);
      },
      textDirection: textDirection,
      textAlign: alignment?.toTextAlign,
      cursorColor: editorState.editorStyle.cursorColor,
      selectionColor: editorState.editorStyle.selectionColor,
    );
  }

  Widget _buildExpandIcon() {
    const buttonHeight = 22.0;
    double top = 0.0;

    if (level != null) {
      // top padding * 2 + button height = height of the heading text
      final textStyle = widget.textStyleBuilder?.call(level ?? 1);
      final fontSize = textStyle?.fontSize;
      final lineHeight = textStyle?.height ?? 1.5;
      if (fontSize != null) {
        top = (fontSize * lineHeight - buttonHeight) / 2;
      }
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 26,
        minHeight: buttonHeight,
      ),
      padding: EdgeInsets.only(top: top, right: 4.0),
      child: AnimatedRotation(
        turns: collapsed ? 0.0 : 0.25,
        duration: const Duration(milliseconds: 200),
        child: FlowyIconButton(
          width: 20.0,
          icon: const Icon(
            Icons.arrow_right,
            size: 18.0,
          ),
          onPressed: onCollapsed,
        ),
      ),
    );
  }

  Future<void> onCollapsed() async {
    final transaction = editorState.transaction
      ..updateNode(node, {
        ToggleListBlockKeys.collapsed: !collapsed,
      });
    await editorState.apply(transaction);
  }
}
