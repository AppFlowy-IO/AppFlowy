import 'package:appflowy/plugins/ai_chat/application/chat_input_action_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input_action_menu.dart';
import 'package:appflowy_backend/log.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class ChatInputActionPage extends Equatable {
  String get title;
  String get pageId;
  dynamic get page;
}

typedef ChatInputMetadata = Map<String, ChatInputActionPage>;

class ChatInputActionControl extends ChatActionHandler {
  ChatInputActionControl({
    required this.textController,
    required this.textFieldFocusNode,
    required this.chatId,
  }) : _commandBloc = ChatInputActionBloc(chatId: chatId);

  final TextEditingController textController;
  final ChatInputActionBloc _commandBloc;
  final FocusNode textFieldFocusNode;
  final String chatId;

  // Private attributes
  bool _isShowActionMenu = false;
  String _atText = "";
  String _prevText = "";
  bool _didLoadViews = false;

  // Getter
  List<String> get tags =>
      _commandBloc.state.selectedPages.map((e) => e.title).toList();

  ChatInputMetadata get metaData => _commandBloc.state.selectedPages.fold(
        <String, ChatInputActionPage>{},
        (map, page) => map..putIfAbsent(page.pageId, () => page),
      );

  void handleKeyEvent(KeyEvent event) {
    // ignore: deprecated_member_use
    if (event is KeyDownEvent || event is RawKeyDownEvent) {
      commandBloc.add(ChatInputActionEvent.handleKeyEvent(event.physicalKey));
    }
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
  void onSelected(ChatInputActionPage page) {
    _atText = "";
    _isShowActionMenu = false;

    _commandBloc.add(ChatInputActionEvent.addPage(page));
    textController.text =
        "${textController.text.replaceAll(_atText, '')}${page.title}";
    _prevText = textController.text;
  }

  @override
  void onExit() {
    _atText = "";
    _isShowActionMenu = false;
    _didLoadViews = false;
    commandBloc.add(const ChatInputActionEvent.filter(""));
  }

  @override
  void onEnter() {
    if (!_didLoadViews) {
      _didLoadViews = true;
      commandBloc.add(const ChatInputActionEvent.started());
    }
    _isShowActionMenu = true;
  }

  @override
  double actionMenuOffsetX() {
    final TextPosition textPosition = textController.selection.extent;
    if (textFieldFocusNode.context == null) {
      return 0;
    }

    final RenderBox renderBox =
        textFieldFocusNode.context?.findRenderObject() as RenderBox;

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: textController.text),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: renderBox.size.width,
      maxWidth: renderBox.size.width,
    );

    final Offset caretOffset =
        textPainter.getOffsetForCaret(textPosition, Rect.zero);
    final List<TextBox> boxes = textPainter.getBoxesForSelection(
      TextSelection(
        baseOffset: textPosition.offset,
        extentOffset: textPosition.offset,
      ),
    );

    if (boxes.isNotEmpty) {
      return boxes.last.right;
    }
    return caretOffset.dx;
  }

  bool onTextChanged(String text) {
    final String inputText = text;
    if (_prevText.length > inputText.length) {
      final deleteStartIndex = textController.selection.baseOffset;
      final deleteEndIndex =
          _prevText.length - inputText.length + deleteStartIndex;
      final deletedText = _prevText.substring(deleteStartIndex, deleteEndIndex);
      _commandBloc.add(ChatInputActionEvent.removePage(deletedText));
    }

    // If the action menu is shown, filter the views
    if (_isShowActionMenu) {
      // before filter the views, remove the first character '@' if it exists
      if (inputText.startsWith("@")) {
        final filter = inputText.substring(1);
        commandBloc.add(ChatInputActionEvent.filter(filter));
      }

      // If the text change from "xxx @"" to "xxx", which means user delete the @, we should hide the action menu
      if (_atText.isNotEmpty && !inputText.contains(_atText)) {
        commandBloc.add(
          const ChatInputActionEvent.handleKeyEvent(PhysicalKeyboardKey.escape),
        );
      }
    } else {
      final isTypingNewAt =
          text.endsWith("@") && _prevText.length < text.length;
      if (isTypingNewAt) {
        _atText = text;
        _prevText = text;
        return true;
      }
    }
    _prevText = text;
    return false;
  }

  @override
  void onFilter(String filter) {
    Log.info("filter: $filter");
  }

  @override
  ChatInputActionBloc get commandBloc => _commandBloc;
}
