import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_ai_message_bloc.freezed.dart';

class ChatAIMessageBloc extends Bloc<ChatAIMessageEvent, ChatAIMessageState> {
  ChatAIMessageBloc({
    required Message message,
  }) : super(ChatAIMessageState.initial(message)) {
    on<ChatAIMessageEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {},
          update: (userProfile, deviceId, states) {},
        );
      },
    );
  }
}

@freezed
class ChatAIMessageEvent with _$ChatAIMessageEvent {
  const factory ChatAIMessageEvent.initial() = Initial;
  const factory ChatAIMessageEvent.update(
    UserProfilePB userProfile,
    String deviceId,
    DocumentAwarenessStatesPB states,
  ) = Update;
}

@freezed
class ChatAIMessageState with _$ChatAIMessageState {
  const factory ChatAIMessageState({
    required Message message,
  }) = _ChatAIMessageState;

  factory ChatAIMessageState.initial(Message message) =>
      ChatAIMessageState(message: message);
}
