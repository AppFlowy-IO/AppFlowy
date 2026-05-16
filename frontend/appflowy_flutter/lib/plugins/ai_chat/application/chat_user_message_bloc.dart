import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_user_message_bloc.freezed.dart';

class ChatUserMessageBloc
    extends Bloc<ChatUserMessageEvent, ChatUserMessageState> {
  ChatUserMessageBloc({
    required this.questionStream,
    required String text,
  }) : super(ChatUserMessageState.initial(text)) {
    _dispatch();
    _startListening();
  }

  final QuestionStream? questionStream;

  void _dispatch() {
    on<ChatUserMessageEvent>(
      (event, emit) {
        event.when(
          updateText: (String text) {
            emit(state.copyWith(text: text));
          },
          updateMessageId: (String messageId) {
            emit(state.copyWith(messageId: messageId));
          },
          receiveError: (String error) {},
          updateQuestionState: (QuestionMessageState newState) {
            emit(state.copyWith(messageState: newState));
          },
        );
      },
    );
  }

  void _startListening() {
    questionStream?.listen(
      onData: (text) {
        if (!isClosed) {
          add(ChatUserMessageEvent.updateText(text));
        }
      },
      onMessageId: (messageId) {
        if (!isClosed) {
          add(ChatUserMessageEvent.updateMessageId(messageId));
        }
      },
      onError: (error) {
        if (!isClosed) {
          add(ChatUserMessageEvent.receiveError(error.toString()));
        }
      },
      onFileIndexStart: (indexName) {
        Log.debug("index start: $indexName");
      },
      onFileIndexEnd: (indexName) {
        Log.info("index end: $indexName");
      },
      onFileIndexFail: (indexName) {
        Log.debug("index fail: $indexName");
      },
      onIndexStart: () {
        if (!isClosed) {
          add(
            const ChatUserMessageEvent.updateQuestionState(
              QuestionMessageState.indexStart(),
            ),
          );
        }
      },
      onIndexEnd: () {
        if (!isClosed) {
          add(
            const ChatUserMessageEvent.updateQuestionState(
              QuestionMessageState.indexEnd(),
            ),
          );
        }
      },
      onDone: () {
        if (!isClosed) {
          add(
            const ChatUserMessageEvent.updateQuestionState(
              QuestionMessageState.finish(),
            ),
          );
        }
      },
    );
  }
}

@freezed
class ChatUserMessageEvent with _$ChatUserMessageEvent {
  const factory ChatUserMessageEvent.updateText(String text) = _UpdateText;
  const factory ChatUserMessageEvent.updateQuestionState(
    QuestionMessageState newState,
  ) = _UpdateQuestionState;
  const factory ChatUserMessageEvent.updateMessageId(String messageId) =
      _UpdateMessageId;
  const factory ChatUserMessageEvent.receiveError(String error) = _ReceiveError;
}

@freezed
class ChatUserMessageState with _$ChatUserMessageState {
  const factory ChatUserMessageState({
    required String text,
    required String? messageId,
    required QuestionMessageState messageState,
  }) = _ChatUserMessageState;

  factory ChatUserMessageState.initial(String message) => ChatUserMessageState(
        text: message,
        messageId: null,
        messageState: const QuestionMessageState.finish(),
      );
}

@freezed
class QuestionMessageState with _$QuestionMessageState {
  const factory QuestionMessageState.indexFileStart(String fileName) =
      _IndexFileStart;
  const factory QuestionMessageState.indexFileEnd(String fileName) =
      _IndexFileEnd;
  const factory QuestionMessageState.indexFileFail(String fileName) =
      _IndexFileFail;

  const factory QuestionMessageState.indexStart() = _IndexStart;
  const factory QuestionMessageState.indexEnd() = _IndexEnd;
  const factory QuestionMessageState.finish() = _Finish;
}

extension QuestionMessageStateX on QuestionMessageState {
  bool get isFinish => this is _Finish;
}
