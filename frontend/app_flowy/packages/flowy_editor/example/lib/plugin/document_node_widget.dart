import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class EditorNodeWidgetBuilder extends NodeWidgetBuilder {
  EditorNodeWidgetBuilder.create({
    required super.editorState,
    required super.node,
    required super.key,
  }) : super.create();

  @override
  Widget build(BuildContext buildContext) {
    return SingleChildScrollView(
      key: key,
      child: _EditorNodeWidget(
        node: node,
        editorState: editorState,
      ),
    );
  }
}

class _EditorNodeWidget extends StatelessWidget {
  final Node node;
  final EditorState editorState;

  const _EditorNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(),
          (recognizer) {
            recognizer
              ..onStart = _onPanStart
              ..onUpdate = _onPanUpdate
              ..onEnd = _onPanEnd;
          },
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (recongizer) {
            recongizer..onTap = _onTap;
          },
        )
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: node.children
              .map(
                (e) => editorState.renderPlugins.buildWidget(
                  context: NodeWidgetContext(
                    buildContext: context,
                    node: e,
                    editorState: editorState,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _onTap() {
    editorState.panStartOffset = null;
    editorState.panEndOffset = null;
    editorState.updateSelection();
  }

  void _onPanStart(DragStartDetails details) {
    editorState.panStartOffset = details.globalPosition;
    editorState.updateSelection();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    editorState.panEndOffset = details.globalPosition;
    editorState.updateSelection();
  }

  void _onPanEnd(DragEndDetails details) {
    // do nothing
  }
}
