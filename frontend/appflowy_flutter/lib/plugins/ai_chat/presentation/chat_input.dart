import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

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
  });

  final bool? isAttachmentUploading;
  final VoidCallback? onAttachmentPressed;
  final void Function(types.PartialText) onSendPressed;
  final void Function() onStopStreaming;
  final InputOptions options;
  final String chatId;
  final bool isStreaming;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

/// [ChatInput] widget state.
class _ChatInputState extends State<ChatInput> {
  late final _inputFocusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (event.physicalKey == PhysicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.physicalKeysPressed.any(
            (el) => <PhysicalKeyboardKey>{
              PhysicalKeyboardKey.shiftLeft,
              PhysicalKeyboardKey.shiftRight,
            }.contains(el),
          )) {
        if (kIsWeb && _textController.value.isComposingRangeValid) {
          return KeyEventResult.ignored;
        }
        if (event is KeyDownEvent) {
          _handleSendPressed();
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );

  bool _sendButtonVisible = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController =
        widget.options.textEditingController ?? InputTextFieldController();
    _handleSendButtonVisibilityModeChange();
  }

  void _handleSendButtonVisibilityModeChange() {
    _textController.removeListener(_handleTextControllerChange);
    _sendButtonVisible =
        _textController.text.trim() != '' || widget.isStreaming;
    _textController.addListener(_handleTextControllerChange);
  }

  void _handleSendPressed() {
    if (widget.isStreaming) {
      widget.onStopStreaming();
    } else {
      final trimmedText = _textController.text.trim();
      if (trimmedText != '') {
        final partialText = types.PartialText(text: trimmedText);
        widget.onSendPressed(partialText);

        if (widget.options.inputClearMode == InputClearMode.always) {
          _textController.clear();
        }
      }
    }
  }

  void _handleTextControllerChange() {
    if (_textController.value.isComposingRangeValid) {
      return;
    }
    setState(() {
      _sendButtonVisible = _textController.text.trim() != '';
    });
  }

  Widget _inputBuilder() {
    const textPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);
    const inputPadding = EdgeInsets.all(6);

    return Focus(
      autofocus: !widget.options.autofocus,
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
              _sendButton(buttonPadding),
            ],
          ),
        ),
      ),
    );
  }

  Padding _inputTextField(EdgeInsets textPadding) {
    return Padding(
      padding: textPadding,
      child: TextField(
        controller: _textController,
        readOnly: widget.isStreaming,
        focusNode: _inputFocusNode,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: LocaleKeys.chat_inputMessageHint.tr(),
          hintStyle: TextStyle(
            color: AFThemeExtension.of(context).textColor.withOpacity(0.5),
          ),
        ),
        style: TextStyle(
          color: AFThemeExtension.of(context).textColor,
        ),
        enabled: widget.options.enabled,
        autocorrect: widget.options.autocorrect,
        autofocus: widget.options.autofocus,
        enableSuggestions: widget.options.enableSuggestions,
        keyboardType: widget.options.keyboardType,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 10,
        minLines: 1,
        onChanged: widget.options.onTextChanged,
        onTap: widget.options.onTextFieldTap,
      ),
    );
  }

  ConstrainedBox _sendButton(EdgeInsets buttonPadding) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: buttonPadding.bottom + buttonPadding.top + 24,
      ),
      child: Visibility(
        visible: _sendButtonVisible,
        child: Padding(
          padding: buttonPadding,
          child: AccessoryButton(
            onSendPressed: () {
              _handleSendPressed();
            },
            onStopStreaming: () {
              widget.onStopStreaming();
            },
            isStreaming: widget.isStreaming,
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleSendButtonVisibilityModeChange();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _inputFocusNode.requestFocus(),
        child: _inputBuilder(),
      );
}

@immutable
class InputOptions {
  const InputOptions({
    this.inputClearMode = InputClearMode.always,
    this.keyboardType = TextInputType.multiline,
    this.onTextChanged,
    this.onTextFieldTap,
    this.textEditingController,
    this.autocorrect = true,
    this.autofocus = false,
    this.enableSuggestions = true,
    this.enabled = true,
  });

  /// Controls the [ChatInput] clear behavior. Defaults to [InputClearMode.always].
  final InputClearMode inputClearMode;

  /// Controls the [ChatInput] keyboard type. Defaults to [TextInputType.multiline].
  final TextInputType keyboardType;

  /// Will be called whenever the text inside [TextField] changes.
  final void Function(String)? onTextChanged;

  /// Will be called on [TextField] tap.
  final VoidCallback? onTextFieldTap;

  /// Custom [TextEditingController]. If not provided, defaults to the
  /// [InputTextFieldController], which extends [TextEditingController] and has
  /// additional fatures like markdown support. If you want to keep additional
  /// features but still need some methods from the default [TextEditingController],
  /// you can create your own [InputTextFieldController] (imported from this lib)
  /// and pass it here.
  final TextEditingController? textEditingController;

  /// Controls the [TextInput] autocorrect behavior. Defaults to [true].
  final bool autocorrect;

  /// Whether [TextInput] should have focus. Defaults to [false].
  final bool autofocus;

  /// Controls the [TextInput] enableSuggestions behavior. Defaults to [true].
  final bool enableSuggestions;

  /// Controls the [TextInput] enabled behavior. Defaults to [true].
  final bool enabled;
}

final isMobile = defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

class AccessoryButton extends StatelessWidget {
  const AccessoryButton({
    required this.onSendPressed,
    required this.onStopStreaming,
    required this.isStreaming,
    super.key,
  });

  final void Function() onSendPressed;
  final void Function() onStopStreaming;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    if (isStreaming) {
      return FlowyIconButton(
        width: 36,
        icon: FlowySvg(
          FlowySvgs.ai_stream_stop_s,
          size: const Size.square(28),
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: onStopStreaming,
        radius: BorderRadius.circular(18),
        fillColor: AFThemeExtension.of(context).lightGreyHover,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
      );
    } else {
      return FlowyIconButton(
        width: 36,
        fillColor: AFThemeExtension.of(context).lightGreyHover,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        radius: BorderRadius.circular(18),
        icon: FlowySvg(
          FlowySvgs.send_s,
          size: const Size.square(24),
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: onSendPressed,
      );
    }
  }
}
