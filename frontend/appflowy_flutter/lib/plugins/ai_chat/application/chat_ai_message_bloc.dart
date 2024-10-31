import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message_service.dart';

part 'chat_ai_message_bloc.freezed.dart';

class ChatAIMessageBloc extends Bloc<ChatAIMessageEvent, ChatAIMessageState> {
  ChatAIMessageBloc({
    dynamic message,
    String? refSourceJsonString,
    required this.chatId,
    required this.questionId,
  }) : super(
          ChatAIMessageState.initial(
            message,
            messageReferenceSource(refSourceJsonString),
          ),
        ) {
    if (state.stream != null) {
      state.stream!.listen(
        onData: (text) {
          if (!isClosed) {
            add(ChatAIMessageEvent.updateText(text));
          }
        },
        onError: (error) {
          if (!isClosed) {
            add(ChatAIMessageEvent.receiveError(error.toString()));
          }
        },
        onAIResponseLimit: () {
          if (!isClosed) {
            add(const ChatAIMessageEvent.onAIResponseLimit());
          }
        },
        onMetadata: (sources) {
          if (!isClosed) {
            add(ChatAIMessageEvent.receiveSources(sources));
          }
        },
      );

      if (state.stream!.error != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!isClosed) {
            add(ChatAIMessageEvent.receiveError(state.stream!.error!));
          }
        });
      }
    }

    on<ChatAIMessageEvent>(
      (event, emit) async {
        await event.when(
          updateText: (newText) {
            emit(
              state.copyWith(
                text: newText,
                messageState: const MessageState.ready(),
              ),
            );
          },
          receiveError: (error) {
            emit(state.copyWith(messageState: MessageState.onError(error)));
          },
          retry: () {
            if (questionId is! Int64) {
              Log.error("Question id is not Int64: $questionId");
              return;
            }
            emit(
              state.copyWith(
                messageState: const MessageState.loading(),
              ),
            );

            final payload = ChatMessageIdPB(
              chatId: chatId,
              messageId: questionId,
            );
            AIEventGetAnswerForQuestion(payload).send().then((result) {
              if (!isClosed) {
                result.fold(
                  (answer) {
                    add(ChatAIMessageEvent.retryResult(answer.content));
                  },
                  (err) {
                    Log.error("Failed to get answer: $err");
                    add(ChatAIMessageEvent.receiveError(err.toString()));
                  },
                );
              }
            });
          },
          retryResult: (String text) {
            emit(
              state.copyWith(
                text: text,
                messageState: const MessageState.ready(),
              ),
            );
          },
          onAIResponseLimit: () {
            emit(
              state.copyWith(
                messageState: const MessageState.onAIResponseLimit(),
              ),
            );
          },
          receiveSources: (List<ChatMessageRefSource> sources) {
            emit(
              state.copyWith(
                sources: sources,
              ),
            );
          },
        );
      },
    );
  }

  final String chatId;
  final Int64? questionId;
}

@freezed
class ChatAIMessageEvent with _$ChatAIMessageEvent {
  const factory ChatAIMessageEvent.updateText(String text) = _UpdateText;
  const factory ChatAIMessageEvent.receiveError(String error) = _ReceiveError;
  const factory ChatAIMessageEvent.retry() = _Retry;
  const factory ChatAIMessageEvent.retryResult(String text) = _RetryResult;
  const factory ChatAIMessageEvent.onAIResponseLimit() = _OnAIResponseLimit;
  const factory ChatAIMessageEvent.receiveSources(
    List<ChatMessageRefSource> sources,
  ) = _ReceiveMetadata;
}

@freezed
class ChatAIMessageState with _$ChatAIMessageState {
  const factory ChatAIMessageState({
    AnswerStream? stream,
    required String text,
    required MessageState messageState,
    required List<ChatMessageRefSource> sources,
  }) = _ChatAIMessageState;

  factory ChatAIMessageState.initial(
    dynamic text,
    List<ChatMessageRefSource> sources,
  ) {
    return ChatAIMessageState(
      text: text is String ? text : "",
      stream: text is AnswerStream ? text : null,
      messageState: const MessageState.ready(),
      sources: sources,
    );
  }
}

@freezed
class MessageState with _$MessageState {
  const factory MessageState.onError(String error) = _Error;
  const factory MessageState.onAIResponseLimit() = _AIResponseLimit;
  const factory MessageState.ready() = _Ready;
  const factory MessageState.loading() = _Loading;
}
