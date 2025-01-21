import 'package:appflowy/plugins/ai_chat/application/chat_input_control_cubit.dart';
import 'package:appflowy/plugins/ai_chat/presentation/layout_define.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

import 'mentioned_page_text_span.dart';

class PromptInputTextField extends StatelessWidget {
  const PromptInputTextField({
    super.key,
    required this.cubit,
    required this.textController,
    required this.textFieldFocusNode,
    required this.contentPadding,
    this.hintText = "",
  });

  final ChatInputControlCubit cubit;
  final TextEditingController textController;
  final FocusNode textFieldFocusNode;
  final EdgeInsetsGeometry contentPadding;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return ExtendedTextField(
      controller: textController,
      focusNode: textFieldFocusNode,
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: contentPadding,
        hintText: hintText,
        hintStyle: AIChatUILayout.inputHintTextStyle(context),
        isCollapsed: true,
        isDense: true,
      ),
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      minLines: 1,
      maxLines: null,
      style: Theme.of(context).textTheme.bodyMedium,
      specialTextSpanBuilder: PromptInputTextSpanBuilder(
        inputControlCubit: cubit,
        specialTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
