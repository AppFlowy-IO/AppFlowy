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

part 'chat_bloc.freezed.dart';

const loadingMessageId = 'chat_message_loading_id';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ViewPB view,
    required UserProfilePB userProfile,
  }) : super(
          ChatState.initial(
            view,
            userProfile,
          ),
        ) {
    _dispatch();
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
          sendMessage: (String message) {
            _handleSentMessage(message, emit);
            final loadingMessage = CustomMessage(
              author: User(id: state.userProfile.id.toString()),
              id: loadingMessageId,
            );
            final List<Message> allMessages = List.from(state.messages);
            allMessages.insert(0, loadingMessage);
            emit(
              state.copyWith(
                messages: allMessages,
                loadingStatus: const LoadingState.loading(),
              ),
            );
          },
          didReceiveMessages: (List<Message> messages) {
            final List<Message> allMessages = List.from(state.messages);
            allMessages
                .removeWhere((element) => element.id == loadingMessageId);
            allMessages.addAll(messages);
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
              add(ChatEvent.didReceiveMessages(messages));
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
    final result = await ChatEventSendMessage(payload).send();
    result.fold((repeatedMessage) {
      final messages =
          repeatedMessage.items.map((m) => _fromChatMessage(m)).toList();
      if (!isClosed) {
        add(ChatEvent.didReceiveMessages(messages));
      }
    }, (err) {
      Log.error("Failed to send message: $err");
    });
  }
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
  const factory ChatEvent.didReceiveMessages(List<Message> messages) =
      _DidLoadMessages;
  const factory ChatEvent.didLoadPreviousMessages(
      List<Message> messages, bool hasMore,) = _DidLoadPreviousMessages;
}

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required ViewPB view,
    required List<Message> messages,
    required UserProfilePB userProfile,
    required LoadingState loadingStatus,
    required LoadingState loadingPreviousStatus,
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
        hasMore: true,
      );
}

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.finish() = _Finish;
}
