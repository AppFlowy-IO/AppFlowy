import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class EditorEntryWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext context) {
    return EditorNodeWidget(
      key: context.editorState.service.scrollServiceKey,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.type == 'editor';
      });
}

class EditorNodeWidget extends StatefulWidget {
  const EditorNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<EditorNodeWidget> createState() => _EditorNodeWidgetState();
}

class _EditorNodeWidgetState extends State<EditorNodeWidget>
    implements AppFlowyScrollService {
  EdgeDraggingAutoScroller? scroller;
  Offset? position;
  @override
  Widget build(BuildContext context) {
    final children = widget.node.children.toList(growable: false);
    return ListView.builder(
      itemBuilder: (context, index) {
        scroller ??= EdgeDraggingAutoScroller(
          Scrollable.of(context)!,
          onScrollViewScrolled: () {
            if (position != null) {
              startAutoScrollIfNecessary(position!);
            }
          },
        );
        final child = children[index];
        return widget.editorState.service.renderPluginService.buildPluginWidget(
          child is TextNode
              ? NodeWidgetContext<TextNode>(
                  context: context,
                  node: child,
                  editorState: widget.editorState,
                )
              : NodeWidgetContext<Node>(
                  context: context,
                  node: child,
                  editorState: widget.editorState,
                ),
        );
      },
      itemCount: children.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.node.children
          .map(
            (child) => widget.editorState.service.renderPluginService
                .buildPluginWidget(
              child is TextNode
                  ? NodeWidgetContext<TextNode>(
                      context: context,
                      node: child,
                      editorState: widget.editorState,
                    )
                  : NodeWidgetContext<Node>(
                      context: context,
                      node: child,
                      editorState: widget.editorState,
                    ),
            ),
          )
          .toList(),
    );
  }

  @override
  void disable() {
    // TODO: implement disable
  }

  @override
  // TODO: implement dy
  double get dy => throw UnimplementedError();

  @override
  void enable() {
    // TODO: implement enable
  }

  @override
  // TODO: implement maxScrollExtent
  double get maxScrollExtent => throw UnimplementedError();

  @override
  // TODO: implement minScrollExtent
  double get minScrollExtent => throw UnimplementedError();

  @override
  // TODO: implement onePageHeight
  double? get onePageHeight => throw UnimplementedError();

  @override
  // TODO: implement page
  int? get page => throw UnimplementedError();

  @override
  void scrollTo(double dy) {
    // TODO: implement scrollTo
  }

  @override
  void startAutoScrollIfNecessary(Offset position) {
    this.position = position;
    final rect = Rect.fromCenter(center: position, width: 200, height: 30);
    scroller?.startAutoScrollIfNecessary(rect);
  }
}
