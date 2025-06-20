import 'package:flutter/material.dart';

extension FocusNodeExtension on FocusNode {
  Future<void> makeSureHasFocus(ValueGetter<bool> cancelCondition) async {
    final focusNode = this;
    if (cancelCondition.call() || focusNode.hasFocus) return;
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      makeSureHasFocus(cancelCondition);
    });
  }
}
