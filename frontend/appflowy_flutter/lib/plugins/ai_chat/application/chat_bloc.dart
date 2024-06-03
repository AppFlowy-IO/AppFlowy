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

const canRetryKey = "canRetry";

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ViewPB view,
    required UserProfilePB userProfile,
  })  : listener = ChatMessageListener(chatId: view.id),
        chatId = view.id,
        super(
          ChatState.initial(view, userProfile),
        ) {
    _dispatch();

    listener.start(
      chatMessageCallback: _handleChatMessage,
      lastUserSentMessageCallback: (message) {
        if (!isClosed) {
          add(ChatEvent.didSentUserMessage(message));
        }
      },
      chatErrorMessageCallback: (err) {
        if (!isClosed) {
          Log.error("chat error: ${err.errorMessage}");
          final metadata = OnetimeMessageType.serverStreamError.toMap();
          if (state.lastSentMessage != null) {
            metadata[canRetryKey] = "true";
          }
          final error = CustomMessage(
            metadata: metadata,
            author: const User(id: "system"),
            id: 'system',
          );
          add(ChatEvent.streaming([error]));
          add(const ChatEvent.didFinishStreaming());
        }
      },
      latestMessageCallback: (list) {
        if (!isClosed) {
          final messages = list.messages.map(_createChatMessage).toList();
          add(ChatEvent.didLoadLatestMessages(messages));
        }
      },
      prevMessageCallback: (list) {
        if (!isClosed) {
          final messages = list.messages.map(_createChatMessage).toList();
          add(ChatEvent.didLoadPreviousMessages(messages, list.hasMore));
        }
      },
      finishAnswerQuestionCallback: () {
        if (!isClosed) {
          add(const ChatEvent.didFinishStreaming());
          if (state.lastSentMessage != null) {
            final payload = ChatMessageIdPB(
              chatId: chatId,
              messageId: state.lastSentMessage!.messageId,
            );
            //  When user message was sent to the server, we start gettting related question
            ChatEventGetRelatedQuestion(payload).send().then((result) {
              if (!isClosed) {
                result.fold(
                  (list) {
                    add(
                      ChatEvent.didReceiveRelatedQuestion(list.items),
                    );
                  },
                  (err) {
                    Log.error("Failed to get related question: $err");
                  },
                );
              }
            });
          }
        }
      },
    );
  }

  final ChatMessageListener listener;
  final String chatId;

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
          startLoadingPrevMessage: () async {
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
          didLoadPreviousMessages: (List<Message> messages, bool hasMore) {
            Log.debug("did load previous messages: ${messages.length}");
            final uniqueMessages = {...state.messages, ...messages}.toList()
              ..sort((a, b) => b.id.compareTo(a.id));
            emit(
              state.copyWith(
                messages: uniqueMessages,
                loadingPreviousStatus: const LoadingState.finish(),
                hasMorePrevMessage: hasMore,
              ),
            );
          },
          didLoadLatestMessages: (List<Message> messages) {
            final uniqueMessages = {...state.messages, ...messages}.toList()
              ..sort((a, b) => b.id.compareTo(a.id));
            emit(
              state.copyWith(
                messages: uniqueMessages,
                initialLoadingStatus: const LoadingState.finish(),
              ),
            );
          },
          streaming: (List<Message> messages) {
            // filter out loading or error messages
            final allMessages = state.messages.where((element) {
              return !(element.metadata?.containsKey(onetimeMessageType) ==
                  true);
            }).toList();
            allMessages.insertAll(0, messages);
            emit(state.copyWith(messages: allMessages));
          },
          didFinishStreaming: () {
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
                lastSentMessage: null,
                messages: allMessages,
                answerQuestionStatus: const LoadingState.loading(),
                relatedQuestions: [],
              ),
            );
          },
          retryGenerate: () {
            if (state.lastSentMessage == null) {
              return;
            }
            final payload = ChatMessageIdPB(
              chatId: chatId,
              messageId: state.lastSentMessage!.messageId,
            );
            ChatEventGetAnswerForQuestion(payload).send().then((result) {
              if (!isClosed) {
                result.fold(
                  (answer) => _handleChatMessage(answer),
                  (err) {
                    Log.error("Failed to get answer: $err");
                  },
                );
              }
            });
          },
          didReceiveRelatedQuestion: (List<RelatedQuestionPB> questions) {
            final allMessages = state.messages.where((element) {
              return !(element.metadata?.containsKey(onetimeMessageType) ==
                  true);
            }).toList();

            final message = CustomMessage(
              metadata: OnetimeMessageType.relatedQuestion.toMap(),
              author: const User(id: "system"),
              id: 'system',
            );
            allMessages.insert(0, message);
            emit(
              state.copyWith(
                messages: allMessages,
                relatedQuestions: questions,
              ),
            );
          },
          clearReleatedQuestion: () {
            emit(
              state.copyWith(
                relatedQuestions: [],
              ),
            );
          },
          didSentUserMessage: (ChatMessagePB message) {
            emit(
              state.copyWith(
                lastSentMessage: message,
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
      add(ChatEvent.streaming(messages));
    }
  }

  Message _loadingMessage(String id) {
    return CustomMessage(
      author: User(id: id),
      metadata: OnetimeMessageType.loading.toMap(),
      // fake id
      id: 'chat_message_loading_id',
    );
  }

  Message _createChatMessage(ChatMessagePB message) {
    final messageId = message.messageId.toString();
    return TextMessage(
      author: User(id: message.authorId),
      id: messageId,
      text: message.content,
      createdAt: message.createdAt.toInt(),
      repliedMessage: _getReplyMessage(state.messages, messageId),
    );
  }

  Message? _getReplyMessage(List<Message?> messages, String messageId) {
    return messages.firstWhereOrNull((element) => element?.id == messageId);
  }
}

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.initialLoad() = _InitialLoadMessage;
  const factory ChatEvent.sendMessage(String message) = _SendMessage;
  const factory ChatEvent.startLoadingPrevMessage() = _StartLoadPrevMessage;
  const factory ChatEvent.didLoadPreviousMessages(
    List<Message> messages,
    bool hasMore,
  ) = _DidLoadPreviousMessages;
  const factory ChatEvent.didLoadLatestMessages(List<Message> messages) =
      _DidLoadMessages;
  const factory ChatEvent.streaming(List<Message> messages) = _DidStreamMessage;
  const factory ChatEvent.didFinishStreaming() = _FinishStreamingMessage;
  const factory ChatEvent.didReceiveRelatedQuestion(
    List<RelatedQuestionPB> questions,
  ) = _DidReceiveRelatedQueston;
  const factory ChatEvent.clearReleatedQuestion() = _ClearRelatedQuestion;
  const factory ChatEvent.retryGenerate() = _RetryGenerate;
  const factory ChatEvent.didSentUserMessage(ChatMessagePB message) =
      _DidSendUserMessage;
}

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required ViewPB view,
    required List<Message> messages,
    required UserProfilePB userProfile,
    // When opening the chat, the initial loading status will be set as loading.
    //After the initial loading is done, the status will be set as finished.
    required LoadingState initialLoadingStatus,
    // When loading previous messages, the status will be set as loading.
    // After the loading is done, the status will be set as finished.
    required LoadingState loadingPreviousStatus,
    // When sending a user message, the status will be set as loading.
    // After the message is sent, the status will be set as finished.
    required LoadingState answerQuestionStatus,
    // Indicate whether there are more previous messages to load.
    required bool hasMorePrevMessage,
    // The related questions that are received after the user message is sent.
    required List<RelatedQuestionPB> relatedQuestions,
    // The last user message that is sent to the server.
    ChatMessagePB? lastSentMessage,
  }) = _ChatState;

  factory ChatState.initial(ViewPB view, UserProfilePB userProfile) =>
      ChatState(
        view: view,
        messages: [],
        userProfile: userProfile,
        initialLoadingStatus: const LoadingState.finish(),
        loadingPreviousStatus: const LoadingState.finish(),
        answerQuestionStatus: const LoadingState.finish(),
        hasMorePrevMessage: true,
        relatedQuestions: [],
      );
}

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.finish() = _Finish;
}

enum OnetimeMessageType { unknown, loading, serverStreamError, relatedQuestion }

const onetimeMessageType = "OnetimeMessageType";

extension OnetimeMessageTypeExtension on OnetimeMessageType {
  static OnetimeMessageType fromString(String value) {
    switch (value) {
      case 'OnetimeMessageType.loading':
        return OnetimeMessageType.loading;
      case 'OnetimeMessageType.serverStreamError':
        return OnetimeMessageType.serverStreamError;
      case 'OnetimeMessageType.relatedQuestion':
        return OnetimeMessageType.relatedQuestion;
      default:
        Log.error('Unknown OnetimeMessageType: $value');
        return OnetimeMessageType.unknown;
    }
  }

  Map<String, String> toMap() {
    return {
      onetimeMessageType: toString(),
    };
  }
}

OnetimeMessageType? onetimeMessageTypeFromMeta(Map<String, dynamic>? metadata) {
  if (metadata == null) {
    return null;
  }

  for (final entry in metadata.entries) {
    if (entry.key == onetimeMessageType) {
      return OnetimeMessageTypeExtension.fromString(entry.value as String);
    }
  }
  return null;
}
