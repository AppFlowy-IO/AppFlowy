import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../application/chat_input_action_control.dart';

class ChatInputTextSpanBuilder extends SpecialTextSpanBuilder {
  ChatInputTextSpanBuilder({
    required this.inputActionControl,
  });

  final ChatInputActionControl inputActionControl;

  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    int? index,
  }) {
    if (flag == '') {
      return null;
    }

    //index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, AtText.flag)) {
      return AtText(
        inputActionControl,
        textStyle,
        onTap,
        start: index! - (AtText.flag.length - 1),
      );
    }
    return null;
  }
}

class AtText extends SpecialText {
  AtText(
    this.inputActionControl,
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap, {
    this.start,
  }) : super(flag, '', textStyle, onTap: onTap);
  static const String flag = '@';
  final int? start;
  final ChatInputActionControl inputActionControl;

  @override
  bool isEnd(String value) {
    return inputActionControl.tags.contains(value);
  }

  @override
  InlineSpan finishText() {
    final TextStyle? textStyle =
        this.textStyle?.copyWith(color: Colors.blue, fontSize: 15.0);

    final String atText = toString();

    return SpecialTextSpan(
      text: atText,
      actualText: atText,
      start: start!,
      style: textStyle,
      recognizer: (TapGestureRecognizer()
        ..onTap = () {
          onTap?.call(atText);
        }),
    );
  }
}
