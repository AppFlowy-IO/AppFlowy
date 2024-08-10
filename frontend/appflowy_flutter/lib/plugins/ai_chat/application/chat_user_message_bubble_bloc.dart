import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message_service.dart';

part 'chat_user_message_bubble_bloc.freezed.dart';

class ChatUserMessageBubbleBloc
    extends Bloc<ChatUserMessageBubbleEvent, ChatUserMessageBubbleState> {
  ChatUserMessageBubbleBloc({
    required Message message,
    required String? metadata,
  }) : super(
          ChatUserMessageBubbleState.initial(
            message,
            chatFilesFromMetadataString(metadata),
          ),
        ) {
    on<ChatUserMessageBubbleEvent>(
      (event, emit) async {
        event.when(
          initial: () {},
        );
      },
    );
  }
}

@freezed
class ChatUserMessageBubbleEvent with _$ChatUserMessageBubbleEvent {
  const factory ChatUserMessageBubbleEvent.initial() = Initial;
}

@freezed
class ChatUserMessageBubbleState with _$ChatUserMessageBubbleState {
  const factory ChatUserMessageBubbleState({
    required Message message,
    required List<ChatFile> files,
  }) = _ChatUserMessageBubbleState;

  factory ChatUserMessageBubbleState.initial(
    Message message,
    List<ChatFile> files,
  ) =>
      ChatUserMessageBubbleState(message: message, files: files);
}
