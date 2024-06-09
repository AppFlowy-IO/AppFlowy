import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_user_message_bloc.freezed.dart';

class ChatUserMessageBloc
    extends Bloc<ChatUserMessageEvent, ChatUserMessageState> {
  ChatUserMessageBloc({
    required Message message,
  }) : super(ChatUserMessageState.initial(message)) {
    on<ChatUserMessageEvent>(
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
class ChatUserMessageEvent with _$ChatUserMessageEvent {
  const factory ChatUserMessageEvent.initial() = Initial;
  const factory ChatUserMessageEvent.update(
    UserProfilePB userProfile,
    String deviceId,
    DocumentAwarenessStatesPB states,
  ) = Update;
}

@freezed
class ChatUserMessageState with _$ChatUserMessageState {
  const factory ChatUserMessageState({
    required Message message,
    WorkspaceMemberPB? member,
  }) = _ChatUserMessageState;

  factory ChatUserMessageState.initial(Message message) =>
      ChatUserMessageState(message: message);
}
