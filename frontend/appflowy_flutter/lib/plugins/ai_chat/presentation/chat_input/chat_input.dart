import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_file_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_action_control.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input/chat_input_file.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input_action_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mobile_page_selector_sheet.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra/platform_extension.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import 'chat_at_button.dart';
import 'chat_input_attachment.dart';
import 'chat_input_span.dart';
import 'chat_send_button.dart';
import 'layout_define.dart';

class ChatInput extends StatefulWidget {
  /// Creates [ChatInput] widget.
  const ChatInput({
    super.key,
    this.onAttachmentPressed,
    required this.onSendPressed,
    required this.chatId,
    this.options = const InputOptions(),
    required this.isStreaming,
    required this.onStopStreaming,
    required this.hintText,
    required this.aiType,
  });

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

    _inputFocusNode.addListener(() {
      setState(() {});
    });

    _inputActionControl = ChatInputActionControl(
      chatId: widget.chatId,
      textController: _textController,
      textFieldFocusNode: _inputFocusNode,
    );
    _inputFocusNode.requestFocus();
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
    return Padding(
      padding: inputPadding,
      // ignore: use_decorated_box
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _inputFocusNode.hasFocus
                ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
                : Theme.of(context).colorScheme.secondary,
          ),
          borderRadius: borderRadius,
        ),
        child: Material(
          borderRadius: borderRadius,
          color: color,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (context.read<ChatFileBloc>().state.uploadFiles.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 12,
                      bottom: 12,
                      left: textPadding.left + sendButtonSize,
                      right: textPadding.right,
                    ),
                    child: BlocBuilder<ChatFileBloc, ChatFileState>(
                      builder: (context, state) {
                        return ChatInputFile(
                          chatId: widget.chatId,
                          files: state.uploadFiles,
                          onDeleted: (file) => context.read<ChatFileBloc>().add(
                                ChatFileEvent.deleteFile(file),
                              ),
                        );
                      },
                    ),
                  ),

                //
                Row(
                  children: [
                    // TODO(lucas): support mobile
                    if (PlatformExtension.isDesktop &&
                        widget.aiType.isLocalAI())
                      _attachmentButton(buttonPadding),

                    // text field
                    Expanded(child: _inputTextField(context, textPadding)),

                    // mention button
                    _mentionButton(buttonPadding),

                    if (PlatformExtension.isMobile) const HSpace(6.0),

                    // send button
                    _sendButton(buttonPadding),
                  ],
                ),
              ],
            ),
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
      // consume metadata
      final ChatInputMentionMetadata mentionPageMetadata =
          _inputActionControl.consumeMetaData();
      final ChatInputFileMetadata fileMetadata =
          context.read<ChatFileBloc>().consumeMetaData();

      // combine metadata
      final Map<String, dynamic> metadata = {}
        ..addAll(mentionPageMetadata)
        ..addAll(fileMetadata);

      final partialText = types.PartialText(
        text: trimmedText,
        metadata: metadata,
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

  Widget _inputTextField(BuildContext context, EdgeInsets textPadding) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: textPadding,
        child: ExtendedTextField(
          key: _textFieldKey,
          controller: _textController,
          focusNode: _inputFocusNode,
          decoration: _buildInputDecoration(context),
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          minLines: 1,
          maxLines: 10,
          style: _buildTextStyle(context),
          specialTextSpanBuilder: ChatInputTextSpanBuilder(
            inputActionControl: _inputActionControl,
          ),
          onChanged: (text) {
            _handleOnTextChange(context, text);
          },
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    return InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      hintText: widget.hintText,
      focusedBorder: InputBorder.none,
      hintStyle: TextStyle(
        color: AFThemeExtension.of(context).textColor.withOpacity(0.5),
      ),
    );
  }

  TextStyle? _buildTextStyle(BuildContext context) {
    if (!isMobile) {
      return TextStyle(
        color: AFThemeExtension.of(context).textColor,
        fontSize: 15,
      );
    }

    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.2,
        );
  }

  Future<void> _handleOnTextChange(BuildContext context, String text) async {
    if (!_inputActionControl.onTextChanged(text)) {
      return;
    }

    if (PlatformExtension.isDesktop) {
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
    } else {
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
  }

  Widget _sendButton(EdgeInsets buttonPadding) {
    return Padding(
      padding: buttonPadding,
      child: SizedBox.square(
        dimension: sendButtonSize,
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
      ),
    );
  }

  Widget _attachmentButton(EdgeInsets buttonPadding) {
    return Padding(
      padding: buttonPadding,
      child: SizedBox.square(
        dimension: attachButtonSize,
        child: ChatInputAttachment(
          onTap: () async {
            final path = await getIt<FilePickerService>().pickFiles(
              dialogTitle: '',
              type: FileType.custom,
              allowedExtensions: ["pdf"],
            );
            if (path == null) {
              return;
            }

            for (final file in path.files) {
              if (file.path != null) {
                if (mounted) {
                  context
                      .read<ChatFileBloc>()
                      .add(ChatFileEvent.newFile(file.path!, file.name));
                }
              }
            }
          },
        ),
      ),
    );
  }

  Widget _mentionButton(EdgeInsets buttonPadding) {
    return Padding(
      padding: buttonPadding,
      child: SizedBox.square(
        dimension: attachButtonSize,
        child: ChatInputAtButton(
          onTap: () {
            _textController.text += '@';
            if (!isMobile) {
              _inputFocusNode.requestFocus();
            }
            _handleOnTextChange(context, _textController.text);
          },
        ),
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
    if (selectedView == null) {
      handler.onExit();
      return;
    }
    handler.onSelected(ViewActionPage(view: selectedView));
    handler.onExit();
    _inputFocusNode.requestFocus();
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
