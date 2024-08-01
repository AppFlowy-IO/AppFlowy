import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_inline_action_menu.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatTextFieldInterceptor extends ChatActionHandler {
  ChatTextFieldInterceptor({
    required this.textController,
    required this.textFieldFocusNode,
  }) {
    commandBloc.add(const ChatInputActionEvent.started());
  }

  @override
  final ChatInputActionBloc commandBloc = ChatInputActionBloc();
  final TextEditingController textController;
  final FocusNode textFieldFocusNode;
  bool _isShowActionMenu = false;
  String _triggerText = "";

  void handleKeyEvent(KeyEvent event) {
    commandBloc.add(ChatInputActionEvent.handleKeyEvent(event));
  }

  bool canHandleKeyEvent(KeyEvent event) {
    return _isShowActionMenu &&
        <PhysicalKeyboardKey>{
          PhysicalKeyboardKey.arrowDown,
          PhysicalKeyboardKey.arrowUp,
          PhysicalKeyboardKey.enter,
          PhysicalKeyboardKey.escape,
        }.contains(event.physicalKey);
  }

  void dispose() {
    commandBloc.close();
  }

  @override
  void onSelected(ChatActionMenuItem item) {
    _triggerText = "";
    _isShowActionMenu = false;
    textController.clear();
  }

  @override
  void onExit() {
    _triggerText = "";
    _isShowActionMenu = false;
    textFieldFocusNode.addListener(() {});
  }

  @override
  void onEnter() {
    _isShowActionMenu = true;
  }

  bool onTextChanged(String text) {
    if (_isShowActionMenu) {
      // remove first character @
      final filter = text.substring(1);
      commandBloc.add(ChatInputActionEvent.filter(filter));
    } else {
      if (text == "@" && _triggerText.isEmpty) {
        _triggerText = text;
        return true;
      }
    }
    return false;
  }

  @override
  void onFilter(String filter) {
    Log.info("filter: $filter");
  }
}
