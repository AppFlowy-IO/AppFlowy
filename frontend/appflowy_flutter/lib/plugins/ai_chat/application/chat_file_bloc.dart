import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_file_bloc.freezed.dart';

class ChatFileBloc extends Bloc<ChatFileEvent, ChatFileState> {
  ChatFileBloc({
    required String chatId,
    dynamic message,
  }) : super(ChatFileState.initial(message)) {
    on<ChatFileEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {},
          newFile: (String filePath) {
            final payload = ChatFilePB(filePath: filePath, chatId: chatId);
            ChatEventChatWithFile(payload).send();
          },
        );
      },
    );
  }
}

@freezed
class ChatFileEvent with _$ChatFileEvent {
  const factory ChatFileEvent.initial() = Initial;
  const factory ChatFileEvent.newFile(String filePath) = _NewFile;
}

@freezed
class ChatFileState with _$ChatFileState {
  const factory ChatFileState({
    required String text,
  }) = _ChatFileState;

  factory ChatFileState.initial(dynamic text) {
    return ChatFileState(
      text: text is String ? text : "",
    );
  }
}
