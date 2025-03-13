import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

typedef QuoteBlockIconBuilder = Widget Function(
  BuildContext context,
  Node node,
);

class QuoteBlockKeys {
  const QuoteBlockKeys._();

  static const String type = 'quote';

  static const String delta = blockComponentDelta;

  static const String backgroundColor = blockComponentBackgroundColor;

  static const String textDirection = blockComponentTextDirection;
}

Node quoteNode({
  Delta? delta,
  String? textDirection,
  Attributes? attributes,
  Iterable<Node>? children,
}) {
  attributes ??= {'delta': (delta ?? Delta()).toJson()};
  return Node(
    type: QuoteBlockKeys.type,
    attributes: {
      ...attributes,
      if (textDirection != null) QuoteBlockKeys.textDirection: textDirection,
    },
    children: children ?? [],
  );
}

class QuoteBlockComponentBuilder extends BlockComponentBuilder {
  QuoteBlockComponentBuilder({
    super.configuration,
    this.iconBuilder,
  });

  final QuoteBlockIconBuilder? iconBuilder;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return QuoteBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      iconBuilder: iconBuilder,
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

class QuoteBlockComponentWidget extends BlockComponentStatefulWidget {
  const QuoteBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.iconBuilder,
  });

  final QuoteBlockIconBuilder? iconBuilder;

  @override
  State<QuoteBlockComponentWidget> createState() =>
      _QuoteBlockComponentWidgetState();
}

class _QuoteBlockComponentWidgetState extends State<QuoteBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentBackgroundColorMixin,
        BlockComponentTextDirectionMixin,
        BlockComponentAlignMixin,
        NestedBlockComponentStatefulWidgetMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: QuoteBlockKeys.type,
  );

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  ValueNotifier<double> quoteBlockHeightNotifier = ValueNotifier(0);

  StreamSubscription<EditorTransactionValue>? _transactionSubscription;

  final GlobalKey layoutBuilderKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _updateQuoteBlockHeight();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      key: layoutBuilderKey,
      onNotification: (notification) {
        _updateQuoteBlockHeight();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: node.children.isEmpty
            ? buildComponent(context)
            : buildComponentWithChildren(context),
      ),
    );
  }

  @override
  Widget buildComponentWithChildren(BuildContext context) {
    final Widget child = Stack(
      children: [
        Positioned.fill(
          left: UniversalPlatform.isMobile ? padding.left : cachedLeft,
          right: UniversalPlatform.isMobile ? padding.right : 0,
          child: Container(
            color: backgroundColor,
          ),
        ),
        NestedListWidget(
          indentPadding: indentPadding,
          child: buildComponent(context, withBackgroundColor: false),
          children: editorState.renderer.buildList(
            context,
            widget.node.children,
          ),
        ),
      ],
    );

    return child;
  }

  @override
  Widget buildComponent(
    BuildContext context, {
    bool withBackgroundColor = true,
  }) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    Widget child = AppFlowyRichText(
      key: forwardKey,
      delegate: this,
      node: widget.node,
      editorState: editorState,
      textAlign: alignment?.toTextAlign ?? textAlign,
      placeholderText: placeholderText,
      textSpanDecorator: (textSpan) => textSpan.updateTextStyle(
        textStyleWithTextSpan(textSpan: textSpan),
      ),
      placeholderTextSpanDecorator: (textSpan) => textSpan.updateTextStyle(
        placeholderTextStyleWithTextSpan(textSpan: textSpan),
      ),
      textDirection: textDirection,
      cursorColor: editorState.editorStyle.cursorColor,
      selectionColor: editorState.editorStyle.selectionColor,
      cursorWidth: editorState.editorStyle.cursorWidth,
    );

    child = Container(
      width: double.infinity,
      alignment: alignment,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          textDirection: textDirection,
          children: [
            widget.iconBuilder != null
                ? widget.iconBuilder!(context, node)
                : ValueListenableBuilder<double>(
                    valueListenable: quoteBlockHeightNotifier,
                    builder: (context, height, child) {
                      return QuoteIcon(height: height);
                    },
                  ),
            Flexible(
              child: child,
            ),
          ],
        ),
      ),
    );

    child = Container(
      color: withBackgroundColor ? backgroundColor : null,
      child: Padding(
        key: blockComponentKey,
        padding: padding,
        child: child,
      ),
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      selectionAboveBlock: true,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }

    return child;
  }

  void _updateQuoteBlockHeight() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final renderObject = layoutBuilderKey.currentContext?.findRenderObject();
      if (renderObject != null && renderObject is RenderBox) {
        if (UniversalPlatform.isMobile) {
          quoteBlockHeightNotifier.value =
              renderObject.size.height - padding.top;
        } else {
          quoteBlockHeightNotifier.value =
              renderObject.size.height - padding.top * 2;
        }
      } else {
        quoteBlockHeightNotifier.value = 0;
      }
    });
  }
}

class QuoteIcon extends StatelessWidget {
  const QuoteIcon({
    super.key,
    this.height = 0,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final textScaleFactor =
        context.read<EditorState>().editorStyle.textScaleFactor;
    return Container(
      alignment: Alignment.center,
      constraints:
          const BoxConstraints(minWidth: 22, minHeight: 22, maxHeight: 22) *
              textScaleFactor,
      padding: const EdgeInsets.only(right: 6.0),
      child: SizedBox(
        width: 3 * textScaleFactor,
        // use overflow box to ensure the container can overflow the height so that the children of the quote block can have the quote
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: height,
          child: Container(
            width: 3 * textScaleFactor,
            height: height,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
