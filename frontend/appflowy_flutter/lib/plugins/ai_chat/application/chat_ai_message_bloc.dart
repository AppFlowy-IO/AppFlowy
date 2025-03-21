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
            parseMetadata(refSourceJsonString),
          ),
        ) {
    _registerEventHandlers();
    _initializeStreamListener();
    _checkInitialStreamState();
  }

  final String chatId;
  final Int64? questionId;

  void _registerEventHandlers() {
    on<_UpdateText>((event, emit) {
      emit(
        state.copyWith(
          text: event.text,
          messageState: const MessageState.ready(),
        ),
      );
    });

    on<_ReceiveError>((event, emit) {
      emit(state.copyWith(messageState: MessageState.onError(event.error)));
    });

    on<_Retry>((event, emit) async {
      if (questionId == null) {
        Log.error("Question id is not valid: $questionId");
        return;
      }
      emit(state.copyWith(messageState: const MessageState.loading()));
      final payload = ChatMessageIdPB(
        chatId: chatId,
        messageId: questionId,
      );
      final result = await AIEventGetAnswerForQuestion(payload).send();
      if (!isClosed) {
        result.fold(
          (answer) => add(ChatAIMessageEvent.retryResult(answer.content)),
          (err) {
            Log.error("Failed to get answer: $err");
            add(ChatAIMessageEvent.receiveError(err.toString()));
          },
        );
      }
    });

    on<_RetryResult>((event, emit) {
      emit(
        state.copyWith(
          text: event.text,
          messageState: const MessageState.ready(),
        ),
      );
    });

    on<_OnAIResponseLimit>((event, emit) {
      emit(
        state.copyWith(
          messageState: const MessageState.onAIResponseLimit(),
        ),
      );
    });

    on<_OnAIImageResponseLimit>((event, emit) {
      emit(
        state.copyWith(
          messageState: const MessageState.onAIImageResponseLimit(),
        ),
      );
    });

    on<_OnAIMaxRquired>((event, emit) {
      emit(
        state.copyWith(
          messageState: MessageState.onAIMaxRequired(event.message),
        ),
      );
    });

    on<_OnLocalAIInitializing>((event, emit) {
      emit(
        state.copyWith(
          messageState: const MessageState.onInitializingLocalAI(),
        ),
      );
    });

    on<_ReceiveMetadata>((event, emit) {
      Log.debug("AI Steps: ${event.metadata.progress?.step}");
      emit(
        state.copyWith(
          sources: event.metadata.sources,
          progress: event.metadata.progress,
        ),
      );
    });
  }

  void _initializeStreamListener() {
    if (state.stream != null) {
      state.stream!.listen(
        onData: (text) => _safeAdd(ChatAIMessageEvent.updateText(text)),
        onError: (error) =>
            _safeAdd(ChatAIMessageEvent.receiveError(error.toString())),
        onAIResponseLimit: () =>
            _safeAdd(const ChatAIMessageEvent.onAIResponseLimit()),
        onAIImageResponseLimit: () =>
            _safeAdd(const ChatAIMessageEvent.onAIImageResponseLimit()),
        onMetadata: (metadata) =>
            _safeAdd(ChatAIMessageEvent.receiveMetadata(metadata)),
        onAIMaxRequired: (message) {
          Log.info(message);
          _safeAdd(ChatAIMessageEvent.onAIMaxRequired(message));
        },
        onLocalAIInitializing: () =>
            _safeAdd(const ChatAIMessageEvent.onLocalAIInitializing()),
      );
    }
  }

  void _checkInitialStreamState() {
    if (state.stream != null) {
      if (state.stream!.aiLimitReached) {
        add(const ChatAIMessageEvent.onAIResponseLimit());
      } else if (state.stream!.error != null) {
        add(ChatAIMessageEvent.receiveError(state.stream!.error!));
      }
    }
  }

  void _safeAdd(ChatAIMessageEvent event) {
    if (!isClosed) {
      add(event);
    }
  }
}

@freezed
class ChatAIMessageEvent with _$ChatAIMessageEvent {
  const factory ChatAIMessageEvent.updateText(String text) = _UpdateText;
  const factory ChatAIMessageEvent.receiveError(String error) = _ReceiveError;
  const factory ChatAIMessageEvent.retry() = _Retry;
  const factory ChatAIMessageEvent.retryResult(String text) = _RetryResult;
  const factory ChatAIMessageEvent.onAIResponseLimit() = _OnAIResponseLimit;
  const factory ChatAIMessageEvent.onAIImageResponseLimit() =
      _OnAIImageResponseLimit;
  const factory ChatAIMessageEvent.onAIMaxRequired(String message) =
      _OnAIMaxRquired;
  const factory ChatAIMessageEvent.onLocalAIInitializing() =
      _OnLocalAIInitializing;
  const factory ChatAIMessageEvent.receiveMetadata(
    MetadataCollection metadata,
  ) = _ReceiveMetadata;
}

@freezed
class ChatAIMessageState with _$ChatAIMessageState {
  const factory ChatAIMessageState({
    AnswerStream? stream,
    required String text,
    required MessageState messageState,
    required List<ChatMessageRefSource> sources,
    required AIChatProgress? progress,
  }) = _ChatAIMessageState;

  factory ChatAIMessageState.initial(
    dynamic text,
    MetadataCollection metadata,
  ) {
    return ChatAIMessageState(
      text: text is String ? text : "",
      stream: text is AnswerStream ? text : null,
      messageState: const MessageState.ready(),
      sources: metadata.sources,
      progress: metadata.progress,
    );
  }
}

@freezed
class MessageState with _$MessageState {
  const factory MessageState.onError(String error) = _Error;
  const factory MessageState.onAIResponseLimit() = _AIResponseLimit;
  const factory MessageState.onAIImageResponseLimit() = _AIImageResponseLimit;
  const factory MessageState.onAIMaxRequired(String message) = _AIMaxRequired;
  const factory MessageState.onInitializingLocalAI() = _LocalAIInitializing;
  const factory MessageState.ready() = _Ready;
  const factory MessageState.loading() = _Loading;
}
