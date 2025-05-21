import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:provider/provider.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.message,
    required this.child,
    this.sentMessageAlignment = AlignmentDirectional.centerEnd,
    this.receivedMessageAlignment = AlignmentDirectional.centerStart,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
  });

  final Message message;
  final Widget child;
  final AlignmentGeometry sentMessageAlignment;
  final AlignmentGeometry receivedMessageAlignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isSentByMe = context.watch<User>().id == message.author.id;

    return Align(
      alignment: isSentByMe ? sentMessageAlignment : receivedMessageAlignment,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
