import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_ai_message_bloc.freezed.dart';

class ChatAIMessageBloc extends Bloc<ChatAIMessageEvent, ChatAIMessageState> {
  ChatAIMessageBloc({
    dynamic message,
    required this.chatId,
    required this.questionId,
  }) : super(ChatAIMessageState.initial(message)) {
    if (state.stream != null) {
      _subscription = state.stream!.listen((text) {
        if (isClosed) {
          return;
        }

        if (text.startsWith("data:")) {
          add(ChatAIMessageEvent.newText(text.substring(5)));
        } else if (text.startsWith("error:")) {
          add(ChatAIMessageEvent.receiveError(text.substring(5)));
        }
      });

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
          initial: () async {},
          newText: (newText) {
            emit(state.copyWith(text: state.text + newText, error: null));
          },
          receiveError: (error) {
            emit(state.copyWith(error: error));
          },
          retry: () {
            // if (questionId is! Int64) {
            //   Log.error("Question id is not Int64: $questionId");
            //   return const SizedBox.shrink();
            // }
            final payload = ChatMessageIdPB(
              chatId: chatId,
              messageId: questionId,
            );
            ChatEventGetAnswerForQuestion(payload).send().then((result) {
              if (!isClosed) {
                result.fold(
                  (answer) {},
                  (err) {
                    Log.error("Failed to get answer: $err");
                  },
                );
              }
            });
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  StreamSubscription<AnswerStreamElement>? _subscription;
  final String chatId;
  final Int64? questionId;
}

@freezed
class ChatAIMessageEvent with _$ChatAIMessageEvent {
  const factory ChatAIMessageEvent.initial() = Initial;
  const factory ChatAIMessageEvent.newText(String text) = _NewText;
  const factory ChatAIMessageEvent.receiveError(String error) = _ReceiveError;
  const factory ChatAIMessageEvent.retry() = _Retry;
}

@freezed
class ChatAIMessageState with _$ChatAIMessageState {
  const factory ChatAIMessageState({
    AnswerStream? stream,
    String? error,
    required String text,
  }) = _ChatAIMessageState;

  factory ChatAIMessageState.initial(dynamic text) {
    return ChatAIMessageState(
      text: text is String ? text : "",
      stream: text is AnswerStream ? text : null,
    );
  }
}
