import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message_listener.dart';

part 'chat_bloc.freezed.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ViewPB view,
    required UserProfilePB userProfile,
  })  : listener = ChatMessageListener(chatId: view.id),
        super(
          ChatState.initial(view, userProfile),
        ) {
    _dispatch();

    listener.start(
      chatMessageCallback: _handleChatMessage,
      chatErrorMessageCallback: (err) {
        final error = TextMessage(
          metadata: {
            CustomMessageType.streamError.toString():
                CustomMessageType.streamError,
          },
          text: err.errorMessage,
          author: const User(id: "system"),
          id: 'system',
        );
        add(ChatEvent.streamingChatMessage([error]));
      },
      latestMessageCallback: (list) {
        final messages = list.messages.map(_createChatMessage).toList();
        add(ChatEvent.didLoadLatestMessages(messages));
      },
      prevMessageCallback: (list) {
        final messages = list.messages.map(_createChatMessage).toList();
        add(ChatEvent.didLoadPreviousMessages(messages, list.hasMore));
      },
      finishAnswerQuestionCallback: () {
        if (!isClosed) {
          add(const ChatEvent.didFinishStreamingChatMessage());
        }
      },
    );
  }

  final ChatMessageListener listener;

  @override
  Future<void> close() {
    listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<ChatEvent>(
      (event, emit) async {
        await event.when(
          initialLoad: () {
            final payload = LoadNextChatMessagePB(
              chatId: state.view.id,
              limit: Int64(10),
            );
            ChatEventLoadNextMessage(payload).send();
          },
          loadPrevMessage: () async {
            Int64? beforeMessageId;
            if (state.messages.isNotEmpty) {
              beforeMessageId = Int64.parseInt(state.messages.last.id);
            }
            _loadPrevMessage(beforeMessageId);
            emit(
              state.copyWith(
                loadingPreviousStatus: const LoadingState.loading(),
              ),
            );
          },
          didLoadLatestMessages: (List<Message> messages) {
            final uniqueMessages = {...state.messages, ...messages}.toList()
              ..sort((a, b) => b.id.compareTo(a.id));
            emit(
              state.copyWith(
                messages: uniqueMessages,
                loadingStatus: const LoadingState.finish(),
              ),
            );
          },
          didLoadPreviousMessages: (List<Message> messages, bool hasMore) {
            Log.debug("did load previous messages: ${messages.length}");
            final uniqueMessages = {...state.messages, ...messages}.toList()
              ..sort((a, b) => b.id.compareTo(a.id));
            emit(
              state.copyWith(
                messages: uniqueMessages,
                loadingPreviousStatus: const LoadingState.finish(),
                hasMore: hasMore,
              ),
            );
          },
          tapMessage: (Message message) {},
          streamingChatMessage: (List<Message> messages) {
            final allMessages = state.messages.where((element) {
              return !(element.metadata
                          ?.containsValue(CustomMessageType.loading) ==
                      true ||
                  element.metadata
                          ?.containsValue(CustomMessageType.streamError) ==
                      true);
            }).toList();
            allMessages.insertAll(0, messages);
            emit(state.copyWith(messages: allMessages));
          },
          didFinishStreamingChatMessage: () {
            emit(
              state.copyWith(
                answerQuestionStatus: const LoadingState.finish(),
              ),
            );
          },
          sendMessage: (String message) async {
            await _handleSentMessage(message, emit);
            final loadingMessage =
                _loadingMessage(state.userProfile.id.toString());
            final allMessages = List<Message>.from(state.messages)
              ..insert(0, loadingMessage);
            emit(
              state.copyWith(
                messages: allMessages,
                answerQuestionStatus: const LoadingState.loading(),
              ),
            );
          },
        );
      },
    );
  }

  void _loadPrevMessage(Int64? beforeMessageId) {
    final payload = LoadPrevChatMessagePB(
      chatId: state.view.id,
      limit: Int64(10),
      beforeMessageId: beforeMessageId,
    );
    ChatEventLoadPrevMessage(payload).send();
  }

  Future<void> _handleSentMessage(
    String message,
    Emitter<ChatState> emit,
  ) async {
    final payload = SendChatPayloadPB(
      chatId: state.view.id,
      message: message,
      messageType: ChatMessageTypePB.User,
    );
    await ChatEventSendMessage(payload).send();
  }

  void _handleChatMessage(ChatMessagePB pb) {
    if (!isClosed) {
      final message = _createChatMessage(pb);
      final messages = pb.hasFollowing
          ? [_loadingMessage(0.toString()), message]
          : [message];
      add(ChatEvent.streamingChatMessage(messages));
    }
  }

  Message _loadingMessage(String id) {
    return CustomMessage(
      author: User(id: id),
      metadata: {
        CustomMessageType.loading.toString(): CustomMessageType.loading,
      },
      id: 'chat_message_loading_id',
    );
  }

  Message _createChatMessage(ChatMessagePB message) {
    final id = message.messageId.toString();
    return TextMessage(
      author: User(id: message.authorId),
      id: id,
      text: message.content,
      createdAt: message.createdAt.toInt(),
      repliedMessage: _getReplyMessage(state.messages, id),
    );
  }

  Message? _getReplyMessage(List<Message?> messages, String messageId) {
    return messages.firstWhereOrNull((element) => element?.id == messageId);
  }
}

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.sendMessage(String message) = _SendMessage;
  const factory ChatEvent.tapMessage(Message message) = _TapMessage;
  const factory ChatEvent.loadPrevMessage() = _LoadPrevMessage;
  const factory ChatEvent.initialLoad() = _InitialLoadMessage;
  const factory ChatEvent.didLoadLatestMessages(List<Message> messages) =
      _DidLoadMessages;
  const factory ChatEvent.streamingChatMessage(List<Message> messages) =
      _DidStreamMessage;
  const factory ChatEvent.didFinishStreamingChatMessage() =
      _FinishStreamingMessage;
  const factory ChatEvent.didLoadPreviousMessages(
    List<Message> messages,
    bool hasMore,
  ) = _DidLoadPreviousMessages;
}

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required ViewPB view,
    required List<Message> messages,
    required UserProfilePB userProfile,
    required LoadingState loadingStatus,
    required LoadingState loadingPreviousStatus,
    required LoadingState answerQuestionStatus,
    required bool hasMore,
  }) = _ChatState;

  factory ChatState.initial(ViewPB view, UserProfilePB userProfile) =>
      ChatState(
        view: view,
        messages: [],
        userProfile: userProfile,
        loadingStatus: const LoadingState.finish(),
        loadingPreviousStatus: const LoadingState.finish(),
        answerQuestionStatus: const LoadingState.finish(),
        hasMore: true,
      );
}

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.finish() = _Finish;
}

enum CustomMessageType { loading, streamError }
