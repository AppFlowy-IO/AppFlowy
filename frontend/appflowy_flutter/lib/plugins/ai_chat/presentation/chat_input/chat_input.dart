import 'package:appflowy/plugins/ai_chat/application/chat_input_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input_action_menu.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_control.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flowy_infra/platform_extension.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import 'chat_at_button.dart';
import 'chat_send_button.dart';
import 'chat_input_span.dart';

class ChatInput extends StatefulWidget {
  /// Creates [ChatInput] widget.
  const ChatInput({
    super.key,
    this.isAttachmentUploading,
    this.onAttachmentPressed,
    required this.onSendPressed,
    required this.chatId,
    this.options = const InputOptions(),
    required this.isStreaming,
    required this.onStopStreaming,
    required this.hintText,
    required this.aiType,
  });

  final bool? isAttachmentUploading;
  final VoidCallback? onAttachmentPressed;
  final void Function(types.PartialText) onSendPressed;
  final void Function() onStopStreaming;
  final InputOptions options;
  final String chatId;
  final bool isStreaming;
  final String hintText;
  final AIType aiType;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

/// [ChatInput] widget state.
class _ChatInputState extends State<ChatInput> {
  final GlobalKey _textFieldKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  late ChatInputActionControl _inputActionControl;
  late FocusNode _inputFocusNode;
  late TextEditingController _textController;
  bool _sendButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _textController = InputTextFieldController();
    _inputFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        // TODO(lucas): support mobile
        if (PlatformExtension.isDesktop) {
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
        } else {
          return KeyEventResult.ignored;
        }
      },
    );

    _inputActionControl = ChatInputActionControl(
      chatId: widget.chatId,
      textController: _textController,
      textFieldFocusNode: _inputFocusNode,
    );
    _handleSendButtonVisibilityModeChange();
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
    const textPadding = EdgeInsets.symmetric(horizontal: 16);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 2);
    const inputPadding = EdgeInsets.all(6);

    return Focus(
      child: Padding(
        padding: inputPadding,
        child: Material(
          borderRadius: BorderRadius.circular(30),
          color: isMobile
              ? Theme.of(context).colorScheme.surfaceContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          elevation: 0.6,
          child: Row(
            children: [
              if (widget.onAttachmentPressed != null)
                AttachmentButton(
                  isLoading: widget.isAttachmentUploading ?? false,
                  onPressed: widget.onAttachmentPressed,
                  padding: buttonPadding,
                ),
              Expanded(child: _inputTextField(textPadding)),

              // TODO(lucas): support mobile
              if (PlatformExtension.isDesktop &&
                  widget.aiType == const AIType.appflowyAI())
                _atButton(buttonPadding),
              _sendButton(buttonPadding),
              const HSpace(14),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSendButtonVisibilityModeChange() {
    _textController.removeListener(_handleTextControllerChange);
    _sendButtonEnabled =
        _textController.text.trim() != '' || widget.isStreaming;
    _textController.addListener(_handleTextControllerChange);
  }

  void _handleSendPressed() {
    final trimmedText = _textController.text.trim();
    if (trimmedText != '') {
      final partialText = types.PartialText(
        text: trimmedText,
        metadata: _inputActionControl.consumeMetaData(),
      );
      widget.onSendPressed(partialText);
      _textController.clear();
    }
  }

  void _handleTextControllerChange() {
    if (_textController.value.isComposingRangeValid) {
      return;
    }
    setState(() {
      _sendButtonEnabled = _textController.text.trim() != '';
    });
  }

  Widget _inputTextField(EdgeInsets textPadding) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: textPadding,
        child: ExtendedTextField(
          key: _textFieldKey,
          specialTextSpanBuilder:
              ChatInputTextSpanBuilder(inputActionControl: _inputActionControl),
          controller: _textController,
          focusNode: _inputFocusNode,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.hintText,
            focusedBorder: InputBorder.none,
            hintStyle: TextStyle(
              color: AFThemeExtension.of(context).textColor.withOpacity(0.5),
            ),
          ),
          style: TextStyle(
            color: AFThemeExtension.of(context).textColor,
            fontSize: 15,
          ),
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          minLines: 1,
          maxLines: 10,
          onChanged: (text) {
            _handleOnTextChange(context, text);
          },
        ),
      ),
    );
  }

  void _handleOnTextChange(BuildContext context, String text) {
    if (widget.aiType != const AIType.appflowyAI()) {
      return;
    }

    if (PlatformExtension.isDesktop) {
      if (_inputActionControl.onTextChanged(text)) {
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
    } else {
      // TODO(lucas): support mobile
    }
  }

  Widget _sendButton(EdgeInsets buttonPadding) {
    return Padding(
      padding: buttonPadding,
      child: ChatInputSendButton(
        onSendPressed: () {
          if (!_sendButtonEnabled) {
            return;
          }

          if (!widget.isStreaming) {
            widget.onStopStreaming();
            _handleSendPressed();
          }
        },
        onStopStreaming: () => widget.onStopStreaming(),
        isStreaming: widget.isStreaming,
        enabled: _sendButtonEnabled,
      ),
    );
  }

  Widget _atButton(EdgeInsets buttonPadding) {
    return Padding(
      padding: buttonPadding,
      child: ChatInputAtButton(
        onTap: () {
          _textController.text += '@';
          _inputFocusNode.requestFocus();
          _handleOnTextChange(context, _textController.text);
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleSendButtonVisibilityModeChange();
  }
}

final isMobile = defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

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
