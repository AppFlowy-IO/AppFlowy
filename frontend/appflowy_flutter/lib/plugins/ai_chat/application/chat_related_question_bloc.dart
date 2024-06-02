import 'package:appflowy/plugins/ai_chat/application/chat_message_listener.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_related_question_bloc.freezed.dart';

class ChatRelatedMessageBloc
    extends Bloc<ChatRelatedMessageEvent, ChatRelatedMessageState> {
  ChatRelatedMessageBloc({
    required String chatId,
  })  : listener = ChatMessageListener(chatId: chatId),
        super(ChatRelatedMessageState.initial()) {
    on<ChatRelatedMessageEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            listener.start(
              lastSentMessageCallback: (message) {
                if (!isClosed) {
                  add(ChatRelatedMessageEvent.updateLastSentMessage(message));
                }
              },
            );
          },
          didReceiveRelatedQuestion: (List<RelatedQuestionPB> questions) {
            Log.debug("Related questions: $questions");
            emit(
              state.copyWith(
                relatedQuestions: questions,
              ),
            );
          },
          updateLastSentMessage: (ChatMessagePB message) {
            final payload =
                ChatMessageIdPB(chatId: chatId, messageId: message.messageId);
            ChatEventGetRelatedQuestion(payload).send().then((result) {
              if (!isClosed) {
                result.fold(
                  (list) {
                    add(
                      ChatRelatedMessageEvent.didReceiveRelatedQuestion(
                        list.items,
                      ),
                    );
                  },
                  (err) {
                    Log.error("Failed to get related question: $err");
                  },
                );
              }
            });

            emit(
              state.copyWith(
                lastSentMessage: message,
                relatedQuestions: [],
              ),
            );
          },
          clear: () {
            emit(
              state.copyWith(
                relatedQuestions: [],
              ),
            );
          },
        );
      },
    );
  }

  final ChatMessageListener listener;
  @override
  Future<void> close() {
    listener.stop();
    return super.close();
  }
}

@freezed
class ChatRelatedMessageEvent with _$ChatRelatedMessageEvent {
  const factory ChatRelatedMessageEvent.initial() = Initial;
  const factory ChatRelatedMessageEvent.updateLastSentMessage(
    ChatMessagePB message,
  ) = _LastSentMessage;
  const factory ChatRelatedMessageEvent.didReceiveRelatedQuestion(
    List<RelatedQuestionPB> questions,
  ) = _RelatedQuestion;
  const factory ChatRelatedMessageEvent.clear() = _Clear;
}

@freezed
class ChatRelatedMessageState with _$ChatRelatedMessageState {
  const factory ChatRelatedMessageState({
    ChatMessagePB? lastSentMessage,
    @Default([]) List<RelatedQuestionPB> relatedQuestions,
  }) = _ChatRelatedMessageState;

  factory ChatRelatedMessageState.initial() => const ChatRelatedMessageState();
}
