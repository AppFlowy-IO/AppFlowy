import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_prompt_input_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_control.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input/chat_input_file.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input_action_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mobile_page_selector_sheet.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import 'ai_prompt_buttons.dart';
import 'chat_input_span.dart';
import '../layout_define.dart';

class MobileAIPromptInput extends StatefulWidget {
  const MobileAIPromptInput({
    super.key,
    required this.chatId,
    this.options = const InputOptions(),
    required this.isStreaming,
    required this.onStopStreaming,
    required this.onSubmitted,
  });

  final String chatId;
  final InputOptions options;
  final bool isStreaming;
  final void Function() onStopStreaming;
  final void Function(types.PartialText) onSubmitted;

  @override
  State<MobileAIPromptInput> createState() => _MobileAIPromptInputState();
}

class _MobileAIPromptInputState extends State<MobileAIPromptInput> {
  late final ChatInputActionControl _inputActionControl;
  late final FocusNode _inputFocusNode;
  late final TextEditingController _textController;

  late SendButtonState sendButtonState;

  @override
  void initState() {
    super.initState();

    _textController = InputTextFieldController()
      ..addListener(_handleTextControllerChange);

    _inputFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });

    _inputActionControl = ChatInputActionControl(
      chatId: widget.chatId,
      textController: _textController,
      textFieldFocusNode: _inputFocusNode,
    );

    updateSendButtonState();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    updateSendButtonState();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _textController.dispose();
    _inputActionControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4.0,
            offset: Offset(0, -2),
            color: Color.fromRGBO(0, 0, 0, 0.05),
          ),
        ],
        borderRadius: MobileAIPromptSizes.promptFrameRadius,
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MobileAIPromptSizes.attachedFilesBarPadding.vertical +
                  MobileAIPromptSizes.attachedFilesPreviewHeight,
            ),
            child: ChatInputFile(
              chatId: widget.chatId,
              onDeleted: (file) => context
                  .read<AIPromptInputBloc>()
                  .add(AIPromptInputEvent.deleteFile(file)),
            ),
          ),
          Container(
            constraints: const BoxConstraints(
              minHeight: MobileAIPromptSizes.textFieldMinHeight,
              maxHeight: 220,
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(0, 8.0, 12.0, 8.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _inputTextField(context)),
                  _mentionButton(),
                  const HSpace(6.0),
                  _sendButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void updateSendButtonState() {
    if (widget.isStreaming) {
      sendButtonState = SendButtonState.streaming;
    } else if (_textController.text.trim().isEmpty) {
      sendButtonState = SendButtonState.disabled;
    } else {
      sendButtonState = SendButtonState.enabled;
    }
  }

  void _handleSendPressed() {
    final trimmedText = _textController.text.trim();
    _textController.clear();
    if (trimmedText.isEmpty) {
      return;
    }
    // consume metadata
    final ChatInputMentionMetadata mentionPageMetadata =
        _inputActionControl.consumeMetaData();
    final ChatInputFileMetadata fileMetadata =
        context.read<AIPromptInputBloc>().consumeMetadata();

    // combine metadata
    final Map<String, dynamic> metadata = {}
      ..addAll(mentionPageMetadata)
      ..addAll(fileMetadata);

    final partialText = types.PartialText(
      text: trimmedText,
      metadata: metadata,
    );
    widget.onSubmitted(partialText);
  }

  void _handleTextControllerChange() {
    if (_textController.value.isComposingRangeValid) {
      return;
    }
    setState(() => updateSendButtonState());
  }

  Widget _inputTextField(BuildContext context) {
    return BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
      builder: (context, state) {
        return ExtendedTextField(
          controller: _textController,
          focusNode: _inputFocusNode,
          decoration: _buildInputDecoration(state),
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          minLines: 1,
          maxLines: null,
          style: Theme.of(context).textTheme.bodyMedium,
          specialTextSpanBuilder: ChatInputTextSpanBuilder(
            inputActionControl: _inputActionControl,
          ),
          onChanged: (text) {
            _handleOnTextChange(context, text);
          },
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(AIPromptInputState state) {
    return InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: MobileAIPromptSizes.textFieldContentPadding,
      hintText: switch (state.aiType) {
        AIType.appflowyAI => LocaleKeys.chat_inputMessageHint.tr(),
        AIType.localAI => LocaleKeys.chat_inputLocalAIMessageHint.tr()
      },
      isCollapsed: true,
      isDense: true,
    );
  }

  Future<void> _handleOnTextChange(BuildContext context, String text) async {
    if (!_inputActionControl.onTextChanged(text)) {
      return;
    }

    // if the focus node is on focus, unfocus it for better animation
    // otherwise, the page sheet animation will be blocked by the keyboard
    if (_inputFocusNode.hasFocus) {
      _inputFocusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 100), () async {
        await _referPage(_inputActionControl);
      });
    } else {
      await _referPage(_inputActionControl);
    }
  }

  Widget _mentionButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: PromptInputMentionButton(
        iconSize: MobileAIPromptSizes.mentionIconSize,
        buttonSize: MobileAIPromptSizes.sendButtonSize,
        onTap: () {
          _textController.text += '@';
          if (!_inputFocusNode.hasFocus) {
            _inputFocusNode.requestFocus();
          }
          _handleOnTextChange(context, _textController.text);
        },
      ),
    );
  }

  Widget _sendButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: PromptInputSendButton(
        buttonSize: MobileAIPromptSizes.sendButtonSize,
        iconSize: MobileAIPromptSizes.sendButtonSize,
        onSendPressed: _handleSendPressed,
        onStopStreaming: widget.onStopStreaming,
        state: sendButtonState,
      ),
    );
  }

  Future<void> _referPage(ChatActionHandler handler) async {
    handler.onEnter();
    final selectedView = await showPageSelectorSheet(
      context,
      filter: (view) =>
          view.layout.isDocumentView &&
          !view.isSpace &&
          view.parentViewId.isNotEmpty,
    );
    if (selectedView != null) {
      handler.onSelected(ViewActionPage(view: selectedView));
    }
    handler.onExit();
    _inputFocusNode.requestFocus();
  }
}
