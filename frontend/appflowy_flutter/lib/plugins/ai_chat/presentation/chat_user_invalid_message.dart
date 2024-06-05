import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class ChatInvalidUserMessage extends StatelessWidget {
  const ChatInvalidUserMessage({
    required this.message,
    super.key,
  });

  final Message message;
  @override
  Widget build(BuildContext context) {
    final errorMessage = message.metadata?[sendMessageErrorKey] ?? "";
    return Center(
      child: Column(
        children: [
          const Divider(height: 20, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FlowyText(
              errorMessage,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
