import 'package:flutter/material.dart';

abstract class CardCell<T extends CardCellStyle> extends StatefulWidget {
  const CardCell({super.key, required this.style});

  final T style;
}

abstract class CardCellStyle {
  const CardCellStyle({required this.padding});

  final EdgeInsetsGeometry padding;
}

S? isStyleOrNull<S>(CardCellStyle? style) {
  if (style is S) {
    return style as S;
  } else {
    return null;
  }
}

class EditableCardNotifier {
  EditableCardNotifier({bool isEditing = false})
      : isCellEditing = ValueNotifier(isEditing);

  final ValueNotifier<bool> isCellEditing;

  void dispose() {
    isCellEditing.dispose();
  }
}

abstract mixin class EditableCell {
  // Each cell notifier will be bind to the [EditableRowNotifier], which enable
  // the row notifier receive its cells event. For example: begin editing the
  // cell or end editing the cell.
  //
  EditableCardNotifier? get editableNotifier;
}
