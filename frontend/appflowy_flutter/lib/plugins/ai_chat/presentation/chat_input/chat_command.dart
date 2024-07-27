import 'package:appflowy/plugins/ai_chat/presentation/chat_inline_action_menu.dart';
import 'package:flutter/material.dart';

class ChatTextFieldInterceptor {
  String previosText = "";

  ChatActionHandler? onTextChanged(
    String text,
    TextEditingController textController,
    FocusNode textFieldFocusNode,
  ) {
    if (previosText == "/" && text == "/ ") {
      final handler = IndexActionHandler(
        textController: textController,
        textFieldFocusNode: textFieldFocusNode,
      ) as ChatActionHandler;
      return handler;
    }
    previosText = text;
    return null;
  }
}

class FixGrammarMenuItem extends ChatActionMenuItem {
  @override
  String get title => "Fix Grammar";
}

class ImproveWritingMenuItem extends ChatActionMenuItem {
  @override
  String get title => "Improve Writing";
}

class ChatWithFileMenuItem extends ChatActionMenuItem {
  @override
  String get title => "Chat With PDF";
}

class IndexActionHandler extends ChatActionHandler {
  IndexActionHandler({
    required this.textController,
    required this.textFieldFocusNode,
  });

  final TextEditingController textController;
  final FocusNode textFieldFocusNode;

  @override
  List<ChatActionMenuItem> get items => [
        ChatWithFileMenuItem(),
        FixGrammarMenuItem(),
        ImproveWritingMenuItem(),
      ];

  @override
  void onSelected(ChatActionMenuItem item) {
    textController.clear();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => textFieldFocusNode.requestFocus(),
    );
  }

  @override
  void onExit() {
    if (!textFieldFocusNode.hasFocus) {
      textFieldFocusNode.requestFocus();
    }
  }

  @override
  void onEnter() {
    if (textFieldFocusNode.hasFocus) {
      textFieldFocusNode.unfocus();
    }
  }
}
