import 'dart:collection';

import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:nanoid/nanoid.dart';

import 'chat_entity.dart';
import 'chat_message_stream.dart';

/// Returns current Unix timestamp (seconds since epoch)
int timestamp() {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

/// Handles message creation and manipulation for the chat system
class ChatMessageHandler {
  ChatMessageHandler({
    required this.chatId,
    required this.userId,
    required this.chatController,
  });
  final String chatId;
  final String userId;
  final ChatController chatController;

  /// Maps real message IDs to temporary streaming message IDs
  final HashMap<String, String> temporaryMessageIDMap = HashMap();

  String answerStreamMessageId = '';
  String questionStreamMessageId = '';

  /// Create a message from ChatMessagePB object
  Message createTextMessage(ChatMessagePB message) {
    String messageId = message.messageId.toString();

    /// If the message id is in the temporary map, we will use the previous fake message id
    if (temporaryMessageIDMap.containsKey(messageId)) {
      messageId = temporaryMessageIDMap[messageId]!;
    }
    final metadata = message.metadata == 'null' ? '[]' : message.metadata;

    return TextMessage(
      author: User(id: message.authorId),
      id: messageId,
      text: message.content,
      createdAt: message.createdAt.toDateTime(),
      metadata: {
        messageRefSourceJsonStringKey: metadata,
      },
    );
  }

  /// Create a streaming answer message
  Message createAnswerStreamMessage({
    required AnswerStream stream,
    required Int64 questionMessageId,
    String? fakeQuestionMessageId,
  }) {
    answerStreamMessageId = fakeQuestionMessageId == null
        ? (questionMessageId + 1).toString()
        : "${fakeQuestionMessageId}_ans";

    return TextMessage(
      id: answerStreamMessageId,
      text: '',
      author: User(id: "streamId:${nanoid()}"),
      metadata: {
        "$AnswerStream": stream,
        messageQuestionIdKey: questionMessageId,
        "chatId": chatId,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create a streaming question message
  Message createQuestionStreamMessage(
    QuestionStream stream,
    Map<String, dynamic>? sentMetadata,
  ) {
    final now = DateTime.now();
    questionStreamMessageId = timestamp().toString();

    return TextMessage(
      author: User(id: userId),
      metadata: {
        "$QuestionStream": stream,
        "chatId": chatId,
        if (sentMetadata != null)
          messageChatFileListKey: sentMetadata[messageChatFileListKey],
      },
      id: questionStreamMessageId,
      createdAt: now,
      text: '',
    );
  }

  /// Clear error messages from the chat
  void clearErrorMessages() {
    final errorMessages = chatController.messages
        .where(
          (message) =>
              onetimeMessageTypeFromMeta(message.metadata) ==
              OnetimeShotType.error,
        )
        .toList();

    for (final message in errorMessages) {
      chatController.remove(message);
    }
  }

  /// Clear related questions from the chat
  void clearRelatedQuestions() {
    final relatedQuestionMessages = chatController.messages
        .where(
          (message) =>
              onetimeMessageTypeFromMeta(message.metadata) ==
              OnetimeShotType.relatedQuestion,
        )
        .toList();

    for (final message in relatedQuestionMessages) {
      chatController.remove(message);
    }
  }

  /// Checks if a message is a one-time message
  bool isOneTimeMessage(Message message) {
    return message.metadata != null &&
        message.metadata!.containsKey(onetimeShotType);
  }

  /// Get the oldest message that is not a one-time message
  Message? getOldestMessage() {
    return chatController.messages
        .firstWhereOrNull((message) => !isOneTimeMessage(message));
  }

  /// Add a message to the temporary ID map when receiving from server
  void processReceivedMessage(ChatMessagePB pb) {
    // 3 means message response from AI
    if (pb.authorType == 3 && answerStreamMessageId.isNotEmpty) {
      temporaryMessageIDMap.putIfAbsent(
        pb.messageId.toString(),
        () => answerStreamMessageId,
      );
      answerStreamMessageId = '';
    }

    // 1 means message response from User
    if (pb.authorType == 1 && questionStreamMessageId.isNotEmpty) {
      temporaryMessageIDMap.putIfAbsent(
        pb.messageId.toString(),
        () => questionStreamMessageId,
      );
      questionStreamMessageId = '';
    }
  }
}
