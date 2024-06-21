import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:fixnum/fixnum.dart';
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
        event.when(
          initial: () {
            final payload =
                WorkspaceMemberIdPB(uid: Int64.parseInt(message.author.id));
            UserEventGetMemberInfo(payload).send().then((result) {
              if (!isClosed) {
                result.fold((member) {
                  add(ChatUserMessageEvent.didReceiveMemberInfo(member));
                }, (err) {
                  Log.error("Error getting member info: $err");
                });
              }
            });
          },
          didReceiveMemberInfo: (WorkspaceMemberPB memberInfo) {
            emit(state.copyWith(member: memberInfo));
          },
        );
      },
    );
  }
}

@freezed
class ChatUserMessageEvent with _$ChatUserMessageEvent {
  const factory ChatUserMessageEvent.initial() = Initial;
  const factory ChatUserMessageEvent.didReceiveMemberInfo(
    WorkspaceMemberPB memberInfo,
  ) = _MemberInfo;
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
