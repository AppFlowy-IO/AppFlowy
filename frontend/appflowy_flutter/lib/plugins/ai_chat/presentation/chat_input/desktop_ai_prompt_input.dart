import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_prompt_input_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_control.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input/chat_input_file.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input_action_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:universal_platform/universal_platform.dart';

import 'ai_prompt_buttons.dart';
import 'chat_input_span.dart';
import 'layout_define.dart';

class DesktopAIPromptInput extends StatefulWidget {
  const DesktopAIPromptInput({
    super.key,
    required this.chatId,
    required this.indicateFocus,
    this.options = const InputOptions(),
    required this.isStreaming,
    required this.onStopStreaming,
    required this.onSubmitted,
  });

  final String chatId;
  final bool indicateFocus;
  final InputOptions options;
  final bool isStreaming;
  final void Function() onStopStreaming;
  final void Function(types.PartialText) onSubmitted;

  @override
  State<DesktopAIPromptInput> createState() => _DesktopAIPromptInputState();
}

class _DesktopAIPromptInputState extends State<DesktopAIPromptInput> {
  final GlobalKey _textFieldKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();

  late final ChatInputActionControl _inputActionControl;
  late final FocusNode _inputFocusNode;
  late final TextEditingController _textController;

  late SendButtonState sendButtonState;

  @override
  void initState() {
    super.initState();

    _textController = InputTextFieldController()
      ..addListener(_handleTextControllerChange);

    _inputFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (_inputActionControl.canHandleKeyEvent(event)) {
          _inputActionControl.handleKeyEvent(event);
          return KeyEventResult.handled;
        } else {
          return _handleEnterKeyWithoutShift(
            event,
            _textController,
            widget.isStreaming,
            _handleSendPressed,
          );
        }
      },
    )..addListener(() {
        // refresh border color on focus change
        if (widget.indicateFocus) {
          setState(() {});
        }
      });
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
        border: Border.all(
          color: _inputFocusNode.hasFocus && widget.indicateFocus
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        borderRadius: DesktopAIPromptSizes.promptFrameRadius,
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: DesktopAIPromptSizes.attachedFilesBarPadding.vertical +
                  DesktopAIPromptSizes.attachedFilesPreviewHeight,
            ),
            child: TextFieldTapRegion(
              child: ChatInputFile(
                chatId: widget.chatId,
                onDeleted: (file) => context
                    .read<AIPromptInputBloc>()
                    .add(AIPromptInputEvent.deleteFile(file)),
              ),
            ),
          ),
          Stack(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: DesktopAIPromptSizes.textFieldMinHeight +
                      DesktopAIPromptSizes.actionBarHeight,
                  maxHeight: 300,
                ),
                child: _inputTextField(context),
              ),
              Positioned.fill(
                top: null,
                child: TextFieldTapRegion(
                  child: Container(
                    height: DesktopAIPromptSizes.actionBarHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
                      builder: (context, state) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // _predefinedFormatButton(),
                            const Spacer(),
                            _mentionButton(),
                            const HSpace(
                              DesktopAIPromptSizes.actionBarButtonSpacing,
                            ),
                            if (UniversalPlatform.isDesktop &&
                                state.supportChatWithFile) ...[
                              _attachmentButton(),
                              const HSpace(
                                DesktopAIPromptSizes.actionBarButtonSpacing,
                              ),
                            ],
                            _sendButton(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: BlocBuilder<AIPromptInputBloc, AIPromptInputState>(
        builder: (context, state) {
          return ExtendedTextField(
            key: _textFieldKey,
            controller: _textController,
            focusNode: _inputFocusNode,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: DesktopAIPromptSizes.textFieldContentPadding.add(
                const EdgeInsets.only(
                  bottom: DesktopAIPromptSizes.actionBarHeight,
                ),
              ),
              hintText: switch (state.aiType) {
                AIType.appflowyAI => LocaleKeys.chat_inputMessageHint.tr(),
                AIType.localAI => LocaleKeys.chat_inputLocalAIMessageHint.tr()
              },
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
              isCollapsed: true,
              isDense: true,
            ),
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
      ),
    );
  }

  Future<void> _handleOnTextChange(BuildContext context, String text) async {
    if (!_inputActionControl.onTextChanged(text)) {
      return;
    }

    ChatActionsMenu(
      anchor: ChatInputAnchor(
        anchorKey: _textFieldKey,
        layerLink: _layerLink,
      ),
      handler: _inputActionControl,
      context: context,
      style: Theme.of(context).brightness == Brightness.dark
          ? const ChatActionsMenuStyle.dark()
          : const ChatActionsMenuStyle.light(),
    ).show();
  }

  Widget _mentionButton() {
    return PromptInputMentionButton(
      iconSize: DesktopAIPromptSizes.actionBarIconSize,
      buttonSize: DesktopAIPromptSizes.actionBarButtonSize,
      onTap: () {
        _textController.text += '@';
        if (!_inputFocusNode.hasFocus) {
          _inputFocusNode.requestFocus();
        }
        _handleOnTextChange(context, _textController.text);
      },
    );
  }

  Widget _attachmentButton() {
    return PromptInputAttachmentButton(
      onTap: () async {
        final path = await getIt<FilePickerService>().pickFiles(
          dialogTitle: '',
          type: FileType.custom,
          allowedExtensions: ["pdf", "txt", "md"],
        );

        if (path == null) {
          return;
        }

        for (final file in path.files) {
          if (file.path != null) {
            if (mounted) {
              context
                  .read<AIPromptInputBloc>()
                  .add(AIPromptInputEvent.newFile(file.path!, file.name));
            }
          }
        }
      },
    );
  }

  Widget _sendButton() {
    return PromptInputSendButton(
      buttonSize: DesktopAIPromptSizes.actionBarButtonSize,
      iconSize: DesktopAIPromptSizes.sendButtonSize,
      state: sendButtonState,
      onSendPressed: _handleSendPressed,
      onStopStreaming: widget.onStopStreaming,
    );
  }
}

class ChatInputAnchor extends ChatAnchor {
  ChatInputAnchor({
    required this.anchorKey,
    required this.layerLink,
  });

  @override
  final GlobalKey<State<StatefulWidget>> anchorKey;

  @override
  final LayerLink layerLink;
}

/// Handles the key press event for the Enter key without Shift.
///
/// This function checks if the Enter key is pressed without either of the Shift keys.
/// If the conditions are met, it performs the action of sending a message if the
/// text controller is not in a composing range and if the event is a key down event.
///
/// - Returns: A `KeyEventResult` indicating whether the key event was handled or ignored.
KeyEventResult _handleEnterKeyWithoutShift(
  KeyEvent event,
  TextEditingController textController,
  bool isStreaming,
  void Function() handleSendPressed,
) {
  if (event.physicalKey == PhysicalKeyboardKey.enter &&
      !HardwareKeyboard.instance.physicalKeysPressed.any(
        (el) => <PhysicalKeyboardKey>{
          PhysicalKeyboardKey.shiftLeft,
          PhysicalKeyboardKey.shiftRight,
        }.contains(el),
      )) {
    if (textController.value.isComposingRangeValid) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      if (!isStreaming) {
        handleSendPressed();
      }
    }
    return KeyEventResult.handled;
  } else {
    return KeyEventResult.ignored;
  }
}
