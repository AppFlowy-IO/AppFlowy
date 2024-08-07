import 'package:appflowy/plugins/ai_chat/application/chat_member_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_user_message_bloc.freezed.dart';

class ChatUserMessageBloc
    extends Bloc<ChatUserMessageEvent, ChatUserMessageState> {
  ChatUserMessageBloc({
    required Message message,
    required ChatMember? member,
  }) : super(ChatUserMessageState.initial(message, member)) {
    on<ChatUserMessageEvent>(
      (event, emit) async {
        event.when(
          initial: () {},
          refreshMember: (ChatMember member) {
            emit(state.copyWith(member: member));
          },
        );
      },
    );
  }
}

@freezed
class ChatUserMessageEvent with _$ChatUserMessageEvent {
  const factory ChatUserMessageEvent.initial() = Initial;
  const factory ChatUserMessageEvent.refreshMember(ChatMember member) =
      _MemberInfo;
}

@freezed
class ChatUserMessageState with _$ChatUserMessageState {
  const factory ChatUserMessageState({
    required Message message,
    ChatMember? member,
  }) = _ChatUserMessageState;

  factory ChatUserMessageState.initial(
    Message message,
    ChatMember? member,
  ) =>
      ChatUserMessageState(message: message, member: member);
}
