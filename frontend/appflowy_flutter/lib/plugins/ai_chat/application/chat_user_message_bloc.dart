import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message_service.dart';

part 'chat_user_message_bloc.freezed.dart';

class ChatUserMessageBloc
    extends Bloc<ChatUserMessageEvent, ChatUserMessageState> {
  ChatUserMessageBloc({
    required Message message,
    required String? metadata,
  }) : super(
          ChatUserMessageState.initial(
            message,
            chatFilesFromMetadataString(metadata),
          ),
        ) {
    on<ChatUserMessageEvent>(
      (event, emit) async {
        event.when(
          initial: () {},
        );
      },
    );
  }
}

@freezed
class ChatUserMessageEvent with _$ChatUserMessageEvent {
  const factory ChatUserMessageEvent.initial() = Initial;
}

@freezed
class ChatUserMessageState with _$ChatUserMessageState {
  const factory ChatUserMessageState({
    required Message message,
    required List<ChatFile> files,
  }) = _ChatUserMessageState;

  factory ChatUserMessageState.initial(
    Message message,
    List<ChatFile> files,
  ) =>
      ChatUserMessageState(message: message, files: files);
}
