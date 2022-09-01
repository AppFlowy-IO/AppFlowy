import 'package:flutter/material.dart';

/// Editor style configuration
class EditorStyle {
  const EditorStyle({
    required this.padding,
  });

  const EditorStyle.defaultStyle()
      : padding = const EdgeInsets.fromLTRB(200.0, 0.0, 200.0, 0.0);

  /// The margin of the document context from the editor.
  final EdgeInsets padding;

  EditorStyle copyWith({EdgeInsets? padding}) {
    return EditorStyle(
      padding: padding ?? this.padding,
    );
  }
}
