import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

abstract class BuiltInTextWidget extends StatefulWidget {
  const BuiltInTextWidget({
    Key? key,
  }) : super(key: key);

  EditorState get editorState;
  TextNode get textNode;
}

mixin BuiltInStyleMixin<T extends BuiltInTextWidget> on State<T> {
  EdgeInsets get padding {
    final padding = widget.editorState.editorStyle.style(
      widget.editorState,
      widget.textNode,
      'padding',
    );
    if (padding is EdgeInsets) {
      return padding;
    }
    return const EdgeInsets.all(0);
  }

  TextStyle get textStyle {
    final textStyle = widget.editorState.editorStyle.style(
      widget.editorState,
      widget.textNode,
      'textStyle',
    );
    if (textStyle is TextStyle) {
      return textStyle;
    }
    return const TextStyle();
  }

  Size? get iconSize {
    final iconSize = widget.editorState.editorStyle.style(
      widget.editorState,
      widget.textNode,
      'iconSize',
    );
    if (iconSize is Size) {
      return iconSize;
    }
    return const Size.square(18.0);
  }

  EdgeInsets? get iconPadding {
    final iconPadding = widget.editorState.editorStyle.style(
      widget.editorState,
      widget.textNode,
      'iconPadding',
    );
    if (iconPadding is EdgeInsets) {
      return iconPadding;
    }
    return const EdgeInsets.all(0);
  }
}
