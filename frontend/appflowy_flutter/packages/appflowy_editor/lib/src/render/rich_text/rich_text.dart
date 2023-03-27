import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/flutter/overlay.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';
import 'package:appflowy_editor/src/render/selection/cursor_widget.dart';
import 'package:appflowy_editor/src/render/selection/selection_widget.dart';
import 'package:flutter/material.dart' hide Overlay, OverlayEntry;
import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

class RichTextNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return RichTextNodeWidget(
      key: context.node.key,
      textNode: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return true;
      });
}

class RichTextNodeWidget extends BuiltInTextWidget {
  const RichTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  @override
  final TextNode textNode;
  @override
  final EditorState editorState;

  @override
  State<RichTextNodeWidget> createState() => _RichTextNodeWidgetState();
}

// customize

class _RichTextNodeWidgetState extends State<RichTextNodeWidget>
    with SelectableMixin, DefaultSelectable, BuiltInTextWidgetMixin {
  @override
  GlobalKey? get iconKey => null;

  final _richTextKey = GlobalKey(debugLabel: 'rich_text');

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  Offset get baseOffset {
    return textPadding.topLeft;
  }

  EditorStyle get style => widget.editorState.editorStyle;

  EdgeInsets get textPadding => style.textPadding!;

  TextStyle get textStyle => style.textStyle!;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final selection =
          widget.editorState.service.selectionService.currentSelection.value;
      setSelection(selection);
    });
  }

  @override
  Widget buildWithSingle(BuildContext context) {
    return Padding(
      padding: textPadding,
      child: FlowyRichText(
        key: _richTextKey,
        textNode: widget.textNode,
        textSpanDecorator: (textSpan) => textSpan,
        placeholderTextSpanDecorator: (textSpan) =>
            textSpan.updateTextStyle(textStyle),
        lineHeight: widget.editorState.editorStyle.lineHeight,
        editorState: widget.editorState,
      ),
    );
  }

  final List<OverlayEntry> _selectionOverlays = [];
  final List<OverlayEntry> _cursorOverlays = [];

  Selection? _cacheSelection;

  @override
  void setSelection(Selection? selection) {
    if (_cacheSelection == selection) {
      return;
    }
    _cacheSelection = selection;
    _selectionOverlays
      ..forEach((element) => element.remove())
      ..clear();
    _cursorOverlays
      ..forEach((element) => element.remove())
      ..clear();
    if (selection == null) {
      return;
    }
    selection = selection.normalized;
    final path = widget.textNode.path;
    if (path < selection.start.path || path > selection.end.path) {
      return;
    }
    var newSelection = selection.copyWith();
    if (selection.isSingle) {
      if (path.equals(newSelection.start.path)) {
        if (selection.isCollapsed) {
          final rect = getCursorRectInPosition(newSelection.start);
          if (rect != null) {
            final entry = OverlayEntry(
              builder: (context) {
                return CursorWidget(
                  layerLink: widget.textNode.layerLink,
                  rect: rect,
                  color: Colors.blue,
                );
              },
            );
            _cursorOverlays.add(entry);
            Overlay.of(context)?.insertAll(_cursorOverlays);
          }
        } else {
          final rects = getRectsInSelection(newSelection);
          for (final rect in rects) {
            final entry = OverlayEntry(
              builder: (context) {
                return SelectionWidget(
                  layerLink: widget.textNode.layerLink,
                  rect: rect,
                  color: Colors.blue.withOpacity(0.3),
                );
              },
            );
            _selectionOverlays.add(entry);
          }
          Overlay.of(context)?.insertAll(_selectionOverlays);
        }
      }
    } else {
      if (path.equals(newSelection.start.path)) {
        newSelection = newSelection.copyWith(end: end());
      } else if (path.equals(newSelection.end.path)) {
        newSelection = newSelection.copyWith(start: start());
      } else {
        newSelection = Selection(start: start(), end: end());
      }
      final rects = getRectsInSelection(newSelection);
      for (final rect in rects) {
        final entry = OverlayEntry(
          builder: (context) {
            return SelectionWidget(
              layerLink: widget.textNode.layerLink,
              rect: rect,
              color: Colors.blue.withOpacity(0.3),
            );
          },
        );
        _selectionOverlays.add(entry);
      }
      Overlay.of(context)?.insertAll(_selectionOverlays);
    }
  }

  @override
  void dispose() {
    setSelection(null);
    super.dispose();
  }
}
