import 'dart:async';
import 'dart:collection';

import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nanoid/nanoid.dart';

import 'chat_entity.dart';
import 'chat_message_listener.dart';
import 'chat_message_service.dart';

part 'chat_bloc.freezed.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ViewPB view,
    required UserProfilePB userProfile,
  })  : listener = ChatMessageListener(chatId: view.id),
        chatId = view.id,
        super(
          ChatState.initial(view, userProfile),
        ) {
    _startListening();
    _dispatch();
  }

  final ChatMessageListener listener;
  final String chatId;

  /// The last streaming message id
  String lastStreamMessageId = '';

  /// Using a temporary map to associate the real message ID with the last streaming message ID.
  ///
  /// When a message is streaming, it does not have a real message ID. To maintain the relationship
  /// between the real message ID and the last streaming message ID, we use this map to store the associations.
  ///
  /// This map will be updated when receiving a message from the server and its author type
  /// is 3 (AI response).
  final HashMap<String, String> temporaryMessageIDMap = HashMap();

  @override
  Future<void> close() async {
    if (state.answerStream != null) {
      await state.answerStream?.dispose();
    }
    await listener.stop();
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
            AIEventLoadNextMessage(payload).send().then(
              (result) {
                result.fold((list) {
                  if (!isClosed) {
                    final messages =
                        list.messages.map(_createTextMessage).toList();
                    add(ChatEvent.didLoadLatestMessages(messages));
                  }
                }, (err) {
                  Log.error("Failed to load messages: $err");
                });
              },
            );
          },
          // Loading messages
          startLoadingPrevMessage: () async {
            Int64? beforeMessageId;
            final oldestMessage = _getOlderstMessage();
            if (oldestMessage != null) {
              beforeMessageId = Int64.parseInt(oldestMessage.id);
            }
            _loadPrevMessage(beforeMessageId);
            emit(
              state.copyWith(
                loadingPreviousStatus: const ChatLoadingState.loading(),
              ),
            );
          },
          didLoadPreviousMessages: (List<Message> messages, bool hasMore) {
            Log.debug("did load previous messages: ${messages.length}");
            final onetimeMessages = _getOnetimeMessages();
            final allMessages = _perminentMessages();
            final uniqueMessages = {...allMessages, ...messages}.toList()
              ..sort((a, b) => b.id.compareTo(a.id));

            uniqueMessages.insertAll(0, onetimeMessages);

            emit(
              state.copyWith(
                messages: uniqueMessages,
                loadingPreviousStatus: const ChatLoadingState.finish(),
                hasMorePrevMessage: hasMore,
              ),
            );
          },
          didLoadLatestMessages: (List<Message> messages) {
            final onetimeMessages = _getOnetimeMessages();
            final allMessages = _perminentMessages();
            final uniqueMessages = {...allMessages, ...messages}.toList()
              ..sort((a, b) => b.id.compareTo(a.id));
            uniqueMessages.insertAll(0, onetimeMessages);
            emit(
              state.copyWith(
                messages: uniqueMessages,
                initialLoadingStatus: const ChatLoadingState.finish(),
              ),
            );
          },
          // streaming message
          streaming: (Message message) {
            final allMessages = _perminentMessages();
            allMessages.insert(0, message);
            emit(
              state.copyWith(
                messages: allMessages,
                streamingState: const StreamingState.streaming(),
                canSendMessage: false,
              ),
            );
          },
          finishStreaming: () {
            emit(
              state.copyWith(
                streamingState: const StreamingState.done(),
                canSendMessage:
                    state.sendingState == const SendMessageState.done(),
              ),
            );
          },
          didUpdateAnswerStream: (AnswerStream stream) {
            emit(state.copyWith(answerStream: stream));
          },
          stopStream: () async {
            if (state.answerStream == null) {
              return;
            }

            final payload = StopStreamPB(chatId: chatId);
            await AIEventStopStream(payload).send();
            final allMessages = _perminentMessages();
            if (state.streamingState != const StreamingState.done()) {
              // If the streaming is not started, remove the message from the list
              if (!state.answerStream!.hasStarted) {
                allMessages.removeWhere(
                  (element) => element.id == lastStreamMessageId,
                );
                lastStreamMessageId = "";
              }

              // when stop stream, we will set the answer stream to null. Which means the streaming
              // is finished or canceled.
              emit(
                state.copyWith(
                  messages: allMessages,
                  answerStream: null,
                  streamingState: const StreamingState.done(),
                ),
              );
            }
          },
          receveMessage: (Message message) {
            final allMessages = _perminentMessages();
            // remove message with the same id
            allMessages.removeWhere((element) => element.id == message.id);
            allMessages.insert(0, message);
            emit(
              state.copyWith(
                messages: allMessages,
              ),
            );
          },
          sendMessage: (String message, Map<String, dynamic>? metadata) async {
            unawaited(_startStreamingMessage(message, metadata, emit));
            final allMessages = _perminentMessages();
            // allMessages.insert(
            //   0,
            //   CustomMessage(
            //     metadata: OnetimeShotType.sendingMessage.toMap(),
            //     author: User(id: state.userProfile.id.toString()),
            //     id: state.userProfile.id.toString(),
            //   ),
            // );
            emit(
              state.copyWith(
                lastSentMessage: null,
                messages: allMessages,
                relatedQuestions: [],
                sendingState: const SendMessageState.sending(),
                canSendMessage: false,
              ),
            );
          },
          finishSending: (ChatMessagePB message) {
            emit(
              state.copyWith(
                lastSentMessage: message,
                sendingState: const SendMessageState.done(),
                canSendMessage:
                    state.streamingState == const StreamingState.done(),
              ),
            );
          },
          // related question
          didReceiveRelatedQuestion: (List<RelatedQuestionPB> questions) {
            if (questions.isEmpty) {
              return;
            }

            final allMessages = _perminentMessages();
            final message = CustomMessage(
              metadata: OnetimeShotType.relatedQuestion.toMap(),
              author: const User(id: systemUserId),
              id: systemUserId,
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
        );
      },
    );
  }

  void _startListening() {
    listener.start(
      chatMessageCallback: (pb) {
        if (!isClosed) {
          // 3 mean message response from AI
          if (pb.authorType == 3 && lastStreamMessageId.isNotEmpty) {
            temporaryMessageIDMap[pb.messageId.toString()] =
                lastStreamMessageId;
            lastStreamMessageId = "";
          }

          final message = _createTextMessage(pb);
          add(ChatEvent.receveMessage(message));
        }
      },
      chatErrorMessageCallback: (err) {
        if (!isClosed) {
          Log.error("chat error: ${err.errorMessage}");
          add(const ChatEvent.finishStreaming());
        }
      },
      latestMessageCallback: (list) {
        if (!isClosed) {
          final messages = list.messages.map(_createTextMessage).toList();
          add(ChatEvent.didLoadLatestMessages(messages));
        }
      },
      prevMessageCallback: (list) {
        if (!isClosed) {
          final messages = list.messages.map(_createTextMessage).toList();
          add(ChatEvent.didLoadPreviousMessages(messages, list.hasMore));
        }
      },
      finishStreamingCallback: () {
        if (!isClosed) {
          add(const ChatEvent.finishStreaming());
          // The answer strema will bet set to null after the streaming is finished or canceled.
          // so if the answer stream is null, we will not get related question.
          if (state.lastSentMessage != null && state.answerStream != null) {
            final payload = ChatMessageIdPB(
              chatId: chatId,
              messageId: state.lastSentMessage!.messageId,
            );
            //  When user message was sent to the server, we start gettting related question
            AIEventGetRelatedQuestion(payload).send().then((result) {
              if (!isClosed) {
                result.fold(
                  (list) {
                    add(ChatEvent.didReceiveRelatedQuestion(list.items));
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

// Returns the list of messages that are not include one-time messages.
  List<Message> _perminentMessages() {
    final allMessages = state.messages.where((element) {
      return !(element.metadata?.containsKey(onetimeShotType) == true);
    }).toList();

    return allMessages;
  }

  List<Message> _getOnetimeMessages() {
    final messages = state.messages.where((element) {
      return (element.metadata?.containsKey(onetimeShotType) == true);
    }).toList();

    return messages;
  }

  Message? _getOlderstMessage() {
    // get the last message that is not a one-time message
    final message = state.messages.lastWhereOrNull((element) {
      return !(element.metadata?.containsKey(onetimeShotType) == true);
    });
    return message;
  }

  void _loadPrevMessage(Int64? beforeMessageId) {
    final payload = LoadPrevChatMessagePB(
      chatId: state.view.id,
      limit: Int64(10),
      beforeMessageId: beforeMessageId,
    );
    AIEventLoadPrevMessage(payload).send();
  }

  Future<void> _startStreamingMessage(
    String message,
    Map<String, dynamic>? metadata,
    Emitter<ChatState> emit,
  ) async {
    if (state.answerStream != null) {
      await state.answerStream?.dispose();
    }

    final answerStream = AnswerStream();
    add(ChatEvent.didUpdateAnswerStream(answerStream));

    final payload = StreamChatPayloadPB(
      chatId: state.view.id,
      message: message,
      messageType: ChatMessageTypePB.User,
      textStreamPort: Int64(answerStream.nativePort),
      metadata: await metadataPBFromMetadata(metadata),
    );

    // Stream message to the server
    final result = await AIEventStreamMessage(payload).send();
    result.fold(
      (ChatMessagePB question) {
        if (!isClosed) {
          add(ChatEvent.finishSending(question));

          final questionMessageId = question.messageId;
          final message = _createTextMessage(question);
          add(ChatEvent.receveMessage(message));

          final streamAnswer =
              _createStreamMessage(answerStream, questionMessageId);
          add(ChatEvent.streaming(streamAnswer));
        }
      },
      (err) {
        if (!isClosed) {
          Log.error("Failed to send message: ${err.msg}");
          final metadata = OnetimeShotType.invalidSendMesssage.toMap();
          if (err.code != ErrorCode.Internal) {
            metadata[sendMessageErrorKey] = err.msg;
          }

          final error = CustomMessage(
            metadata: metadata,
            author: const User(id: systemUserId),
            id: systemUserId,
          );

          add(ChatEvent.receveMessage(error));
        }
      },
    );
  }

  Message _createStreamMessage(AnswerStream stream, Int64 questionMessageId) {
    final streamMessageId = (questionMessageId + 1).toString();
    lastStreamMessageId = streamMessageId;

    return TextMessage(
      author: User(id: "streamId:${nanoid()}"),
      metadata: {
        "$AnswerStream": stream,
        messageQuestionIdKey: questionMessageId,
        "chatId": chatId,
      },
      id: streamMessageId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: '',
    );
  }

  Message _createTextMessage(ChatMessagePB message) {
    String messageId = message.messageId.toString();

    /// If the message id is in the temporary map, we will use the previous fake message id
    if (temporaryMessageIDMap.containsKey(messageId)) {
      messageId = temporaryMessageIDMap[messageId]!;
    }

    return TextMessage(
      author: User(id: message.authorId),
      id: messageId,
      text: message.content,
      createdAt: message.createdAt.toInt() * 1000,
      metadata: {
        messageMetadataKey: message.metadata,
      },
    );
  }
}

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.initialLoad() = _InitialLoadMessage;

  // send message
  const factory ChatEvent.sendMessage({
    required String message,
    Map<String, dynamic>? metadata,
  }) = _SendMessage;
  const factory ChatEvent.finishSending(ChatMessagePB message) =
      _FinishSendMessage;

// receive message
  const factory ChatEvent.streaming(Message message) = _StreamingMessage;
  const factory ChatEvent.receveMessage(Message message) = _ReceiveMessage;
  const factory ChatEvent.finishStreaming() = _FinishStreamingMessage;

// loading messages
  const factory ChatEvent.startLoadingPrevMessage() = _StartLoadPrevMessage;
  const factory ChatEvent.didLoadPreviousMessages(
    List<Message> messages,
    bool hasMore,
  ) = _DidLoadPreviousMessages;
  const factory ChatEvent.didLoadLatestMessages(List<Message> messages) =
      _DidLoadMessages;

// related questions
  const factory ChatEvent.didReceiveRelatedQuestion(
    List<RelatedQuestionPB> questions,
  ) = _DidReceiveRelatedQueston;
  const factory ChatEvent.clearReleatedQuestion() = _ClearRelatedQuestion;

  const factory ChatEvent.didUpdateAnswerStream(
    AnswerStream stream,
  ) = _DidUpdateAnswerStream;
  const factory ChatEvent.stopStream() = _StopStream;
}

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required ViewPB view,
    required List<Message> messages,
    required UserProfilePB userProfile,
    // When opening the chat, the initial loading status will be set as loading.
    //After the initial loading is done, the status will be set as finished.
    required ChatLoadingState initialLoadingStatus,
    // When loading previous messages, the status will be set as loading.
    // After the loading is done, the status will be set as finished.
    required ChatLoadingState loadingPreviousStatus,
    // When sending a user message, the status will be set as loading.
    // After the message is sent, the status will be set as finished.
    required StreamingState streamingState,
    required SendMessageState sendingState,
    // Indicate whether there are more previous messages to load.
    required bool hasMorePrevMessage,
    // The related questions that are received after the user message is sent.
    required List<RelatedQuestionPB> relatedQuestions,
    // The last user message that is sent to the server.
    ChatMessagePB? lastSentMessage,
    AnswerStream? answerStream,
    @Default(true) bool canSendMessage,
  }) = _ChatState;

  factory ChatState.initial(ViewPB view, UserProfilePB userProfile) =>
      ChatState(
        view: view,
        messages: [],
        userProfile: userProfile,
        initialLoadingStatus: const ChatLoadingState.finish(),
        loadingPreviousStatus: const ChatLoadingState.finish(),
        streamingState: const StreamingState.done(),
        sendingState: const SendMessageState.done(),
        hasMorePrevMessage: true,
        relatedQuestions: [],
      );
}

bool isOtherUserMessage(Message message) {
  return message.author.id != aiResponseUserId &&
      message.author.id != systemUserId &&
      !message.author.id.startsWith("streamId:");
}
