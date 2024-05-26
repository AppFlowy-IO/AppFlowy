import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message_listener.dart';

part 'chat_bloc.freezed.dart';

const loadingMessageId = 'chat_message_loading_id';

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
      chatErrorMessageCallback: _handleErrorMessage,
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
          loadMessage: () async {
            Int64? beforeMessageId;
            if (state.messages.isNotEmpty) {
              beforeMessageId = Int64.parseInt(state.messages.last.id);
            }

            _loadMessage(beforeMessageId);
            if (beforeMessageId == null) {
              emit(
                state.copyWith(
                  loadingStatus: const LoadingState.loading(),
                ),
              );
            } else {
              emit(
                state.copyWith(
                  loadingPreviousStatus: const LoadingState.loading(),
                ),
              );
            }
          },
          didLoadMessages: (List<Message> messages) {
            final List<Message> allMessages = List.from(state.messages);
            allMessages
                .removeWhere((element) => element.id == loadingMessageId);
            allMessages.insertAll(0, messages);
            emit(
              state.copyWith(
                messages: allMessages,
                loadingStatus: const LoadingState.finish(),
              ),
            );
          },
          didLoadPreviousMessages: (List<Message> messages, bool hasMore) {
            final List<Message> allMessages = List.from(state.messages);
            allMessages.addAll(messages);
            Log.info("did load previous messages: ${allMessages.length}");
            emit(
              state.copyWith(
                messages: allMessages,
                loadingPreviousStatus: const LoadingState.finish(),
                hasMore: hasMore,
              ),
            );
          },
          tapMessage: (Message message) {},
          streamingChatMessage: (List<Message> messages) {
            final List<Message> allMessages = List.from(state.messages);
            allMessages
                .removeWhere((element) => element.id == loadingMessageId);
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
                _loaddingMessage(state.userProfile.id.toString());
            final List<Message> allMessages = List.from(state.messages);
            allMessages.insert(0, loadingMessage);
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


  void _loadMessage(
    Int64? beforeMessageId,
  ) {
    final payload = LoadChatMessagePB(
      chatId: state.view.id,
      limit: Int64(10),
      beforeMessageId: beforeMessageId,
    );
    ChatEventLoadMessage(payload).send().then((result) {
      result.fold(
        (list) {
          final messages =
              list.messages.map((m) => _fromChatMessage(m)).toList();
          if (!isClosed) {
            if (beforeMessageId != null) {
              add(ChatEvent.didLoadPreviousMessages(messages, list.hasMore));
            } else {
              add(ChatEvent.didLoadMessages(messages));
            }
          }
        },
        (err) {
          Log.error("Failed to load message: $err");
        },
      );
    });
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
      final message = _fromChatMessage(pb);
      final List<Message> messages = [];
      if (pb.hasFollowing) {
        messages.addAll([_loaddingMessage(0.toString()), message]);
      } else {
        messages.add(message);
      }
      add(ChatEvent.streamingChatMessage(messages));
    }
  }

  void _handleErrorMessage(ChatMessageErrorPB message) {
    if (!isClosed) {
      Log.error("Received error: $message");
    }
  }
}

Message _loaddingMessage(String id) {
  final loadingMessage = CustomMessage(
    author: User(id: id),
    id: loadingMessageId,
  );
  return loadingMessage;
}

Message _fromChatMessage(ChatMessagePB message) {
  return TextMessage(
    author: User(id: message.authorId),
    id: message.messageId.toString(),
    text: message.content,
    createdAt: message.createdAt.toInt(),
  );
}

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.sendMessage(String message) = _SendMessage;
  const factory ChatEvent.tapMessage(Message message) = _TapMessage;
  const factory ChatEvent.loadMessage() = _LoadMessage;
  const factory ChatEvent.didLoadMessages(List<Message> messages) =
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

  factory ChatState.initial(
    ViewPB view,
    UserProfilePB userProfile,
  ) =>
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
