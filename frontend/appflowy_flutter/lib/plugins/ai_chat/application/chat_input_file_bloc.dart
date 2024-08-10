import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_input_file_bloc.freezed.dart';

class ChatInputFileBloc extends Bloc<ChatInputFileEvent, ChatInputFileState> {
  ChatInputFileBloc({
    required String chatId,
    required this.file,
  }) : super(const ChatInputFileState()) {
    on<ChatInputFileEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final payload = ChatFilePB(
              filePath: file.filePath,
              chatId: chatId,
            );
            unawaited(
              AIEventChatWithFile(payload).send().then((result) {
                if (!isClosed) {
                  result.fold(
                    (_) {
                      add(
                        const ChatInputFileEvent.updateUploadState(
                          UploadFileIndicator.finish(),
                        ),
                      );
                    },
                    (err) {
                      add(
                        ChatInputFileEvent.updateUploadState(
                          UploadFileIndicator.error(err.toString()),
                        ),
                      );
                    },
                  );
                }
              }),
            );
          },
          updateUploadState: (UploadFileIndicator indicator) {
            emit(state.copyWith(uploadFileIndicator: indicator));
          },
        );
      },
    );
  }

  final ChatFile file;
}

@freezed
class ChatInputFileEvent with _$ChatInputFileEvent {
  const factory ChatInputFileEvent.initial() = Initial;
  const factory ChatInputFileEvent.updateUploadState(
    UploadFileIndicator indicator,
  ) = _UpdateUploadState;
}

@freezed
class ChatInputFileState with _$ChatInputFileState {
  const factory ChatInputFileState({
    UploadFileIndicator? uploadFileIndicator,
  }) = _ChatInputFileState;
}

@freezed
class UploadFileIndicator with _$UploadFileIndicator {
  const factory UploadFileIndicator.finish() = _Finish;
  const factory UploadFileIndicator.uploading() = _Uploading;
  const factory UploadFileIndicator.error(String error) = _Error;
}
