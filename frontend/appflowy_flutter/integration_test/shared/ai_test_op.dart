import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_content_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/ai_writer_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/operations/ai_writer_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/util.dart';
import 'util.dart';

extension AppFlowyAITest on WidgetTester {
  Future<void> selectAIWriter(AiWriterCommand command) async {
    await tapButton(find.byType(AiWriterToolbarActionList));
    await tapButton(find.text(command.i18n));
    await pumpAndSettle();
  }

  Future<void> selectModel(String modelName) async {
    await tapButton(find.byType(SelectModelMenu));
    await tapButton(find.text(modelName));
    await pumpAndSettle();
  }

  Future<void> enterTextInPromptTextField(String text) async {
    // Wait for the text field to be visible
    await pumpAndSettle();

    // Find the ExtendedTextField widget
    final textField = find.descendant(
      of: find.byType(PromptInputTextField),
      matching: find.byType(TextField),
    );
    expect(textField, findsOneWidget, reason: 'ExtendedTextField not found');

    final widget = element(textField).widget as TextField;
    expect(widget.enabled, isTrue, reason: 'TextField is not enabled');

    await tap(textField);

    testTextInput.enterText(text);
    await pumpAndSettle(const Duration(milliseconds: 300));
  }

  ChatBloc getCurrentChatBloc() {
    return element(find.byType(ChatContentPage)).read<ChatBloc>();
  }

  Future<void> loadDefaultMessages(List<Message> messages) async {
    final chatBloc = getCurrentChatBloc();
    chatBloc.add(ChatEvent.didLoadLatestMessages(messages));
    await blocResponseFuture();
  }

  Future<void> sendUserMessage(Message message) async {
    final chatBloc = getCurrentChatBloc();
    // using received message to simulate the user message
    chatBloc.add(ChatEvent.receiveMessage(message));
    await blocResponseFuture();
  }

  Future<void> receiveAIMessage(Message message) async {
    final chatBloc = getCurrentChatBloc();
    chatBloc.add(ChatEvent.receiveMessage(message));
    await blocResponseFuture();
  }
}
