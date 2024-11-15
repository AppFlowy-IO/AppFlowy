import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:equatable/equatable.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_member_bloc.freezed.dart';

class ChatMemberBloc extends Bloc<ChatMemberEvent, ChatMemberState> {
  ChatMemberBloc() : super(const ChatMemberState()) {
    on<ChatMemberEvent>(
      (event, emit) async {
        event.when(
          receiveMemberInfo: (String id, WorkspaceMemberPB memberInfo) {
            final members = Map<String, ChatMember>.from(state.members);
            members[id] = ChatMember(info: memberInfo);
            emit(state.copyWith(members: members));
          },
          getMemberInfo: (String userId) {
            if (state.members.containsKey(userId)) {
              // Member info already exists. Debouncing refresh member info from backend would be better.
              return;
            }

            final payload = WorkspaceMemberIdPB(
              uid: Int64.parseInt(userId),
            );
            UserEventGetMemberInfo(payload).send().then((result) {
              if (!isClosed) {
                result.fold((member) {
                  add(
                    ChatMemberEvent.receiveMemberInfo(
                      userId,
                      member,
                    ),
                  );
                }, (err) {
                  Log.error("Error getting member info: $err");
                });
              }
            });
          },
        );
      },
    );
  }
}

@freezed
class ChatMemberEvent with _$ChatMemberEvent {
  const factory ChatMemberEvent.getMemberInfo(
    String userId,
  ) = _GetMemberInfo;
  const factory ChatMemberEvent.receiveMemberInfo(
    String id,
    WorkspaceMemberPB memberInfo,
  ) = _ReceiveMemberInfo;
}

@freezed
class ChatMemberState with _$ChatMemberState {
  const factory ChatMemberState({
    @Default({}) Map<String, ChatMember> members,
  }) = _ChatMemberState;
}

class ChatMember extends Equatable {
  ChatMember({
    required this.info,
  });
  final DateTime _date = DateTime.now();
  final WorkspaceMemberPB info;

  @override
  List<Object?> get props => [_date, info];
}
