import 'dart:async';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_entity.dart';
import 'chat_message_handler.dart';
import 'chat_message_listener.dart';
import 'chat_message_stream.dart';
import 'chat_settings_manager.dart';
import 'chat_stream_manager.dart';

part 'chat_bloc.freezed.dart';

/// Returns current Unix timestamp (seconds since epoch)
int timestamp() {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.chatId,
    required this.userId,
  })  : chatController = InMemoryChatController(),
        listener = ChatMessageListener(chatId: chatId),
        super(ChatState.initial()) {
    // Initialize managers
    _messageHandler = ChatMessageHandler(
      chatId: chatId,
      userId: userId,
      chatController: chatController,
    );

    _streamManager = ChatStreamManager(chatId);
    _settingsManager = ChatSettingsManager(chatId: chatId);

    _startListening();
    _dispatch();
    _loadMessages();
    _loadSettings();
  }

  final String chatId;
  final String userId;
  final ChatMessageListener listener;
  final ChatController chatController;

  // Managers
  late final ChatMessageHandler _messageHandler;
  late final ChatStreamManager _streamManager;
  late final ChatSettingsManager _settingsManager;

  ChatMessagePB? lastSentMessage;

  bool isLoadingPreviousMessages = false;
  bool hasMorePreviousMessages = true;
  bool isFetchingRelatedQuestions = false;
  bool shouldFetchRelatedQuestions = false;

  // Accessor for selected sources
  ValueNotifier<List<String>> get selectedSourcesNotifier =>
      _settingsManager.selectedSourcesNotifier;

  @override
  Future<void> close() async {
    // Safely dispose all resources
    await _streamManager.dispose();
    await listener.stop();

    final request = ViewIdPB(value: chatId);
    unawaited(FolderEventCloseView(request).send());

    _settingsManager.dispose();
    chatController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<ChatEvent>((event, emit) async {
      await event.when(
        // Chat settings
        didReceiveChatSettings: (settings) async =>
            _handleChatSettings(settings),
        updateSelectedSources: (selectedSourcesIds) async =>
            _handleUpdateSources(selectedSourcesIds),

        // Message loading
        didLoadLatestMessages: (messages) async =>
            _handleLatestMessages(messages, emit),
        loadPreviousMessages: () async => _loadPreviousMessagesIfNeeded(),
        didLoadPreviousMessages: (messages, hasMore) async =>
            _handlePreviousMessages(messages, hasMore),

        // Message handling
        receiveMessage: (message) async => _handleReceiveMessage(message),

        // Sending messages
        sendMessage: (message, format, metadata) async =>
            _handleSendMessage(message, format, metadata, emit),
        finishSending: () async => emit(
          state.copyWith(
              promptResponseState: PromptResponseState.streamingAnswer),
        ),

        // Stream control
        stopStream: () async => _handleStopStream(emit),
        failedSending: () async => _handleFailedSending(emit),

        // Answer regeneration
        regenerateAnswer: (id, format, model) async =>
            _handleRegenerateAnswer(id, format, model, emit),

        // Streaming completion
        didFinishAnswerStream: () async => emit(
          state.copyWith(promptResponseState: PromptResponseState.ready),
        ),

        // Related questions
        didReceiveRelatedQuestions: (questions) async =>
            _handleRelatedQuestions(questions),

        // Message management
        deleteMessage: (message) async => chatController.remove(message),

        // AI follow-up
        onAIFollowUp: (followUpData) async {
          shouldFetchRelatedQuestions =
              followUpData.shouldGenerateRelatedQuestion;
        },
      );
    });
  }

  // Chat settings handlers
  void _handleChatSettings(ChatSettingsPB settings) {
    _settingsManager.selectedSourcesNotifier.value = settings.ragIds;
  }

  Future<void> _handleUpdateSources(List<String> selectedSourcesIds) async {
    await _settingsManager.updateSelectedSources(selectedSourcesIds);
  }

  // Message loading handlers
  Future<void> _handleLatestMessages(
    List<Message> messages,
    Emitter<ChatState> emit,
  ) async {
    for (final message in messages) {
      await chatController.insert(message, index: 0);
    }

    // Check if emit is still valid after async operations
    if (emit.isDone) {
      return;
    }

    switch (state.loadingState) {
      case LoadChatMessageStatus.loading when chatController.messages.isEmpty:
        emit(state.copyWith(loadingState: LoadChatMessageStatus.loadingRemote));
        break;
      case LoadChatMessageStatus.loading:
      case LoadChatMessageStatus.loadingRemote:
        emit(state.copyWith(loadingState: LoadChatMessageStatus.ready));
        break;
      default:
        break;
    }
  }

  void _handlePreviousMessages(List<Message> messages, bool hasMore) {
    for (final message in messages) {
      chatController.insert(message, index: 0);
    }

    isLoadingPreviousMessages = false;
    hasMorePreviousMessages = hasMore;
  }

  // Message handling
  void _handleReceiveMessage(Message message) {
    final oldMessage =
        chatController.messages.firstWhereOrNull((m) => m.id == message.id);
    if (oldMessage == null) {
      chatController.insert(message);
    } else {
      chatController.update(oldMessage, message);
    }
  }

  // Message sending handlers
  void _handleSendMessage(
    String message,
    PredefinedFormat? format,
    Map<String, dynamic>? metadata,
    Emitter<ChatState> emit,
  ) {
    _messageHandler.clearErrorMessages();
    emit(state.copyWith(clearErrorMessages: !state.clearErrorMessages));

    _messageHandler.clearRelatedQuestions();
    _startStreamingMessage(message, format, metadata);
    lastSentMessage = null;

    isFetchingRelatedQuestions = false;
    shouldFetchRelatedQuestions = format == null || format.imageFormat.hasText;

    emit(
      state.copyWith(
        promptResponseState: PromptResponseState.sendingQuestion,
      ),
    );
  }

  // Stream control handlers
  Future<void> _handleStopStream(Emitter<ChatState> emit) async {
    await _streamManager.stopStream();

    // Allow user input
    emit(state.copyWith(promptResponseState: PromptResponseState.ready));

    // No need to remove old message if stream has started already
    if (_streamManager.hasAnswerStreamStarted) {
      return;
    }

    // Remove the non-started message from the list
    final message = chatController.messages.lastWhereOrNull(
      (e) => e.id == _messageHandler.answerStreamMessageId,
    );
    if (message != null) {
      await chatController.remove(message);
    }

    await _streamManager.disposeAnswerStream();
  }

  void _handleFailedSending(Emitter<ChatState> emit) {
    final lastMessage = chatController.messages.lastOrNull;
    if (lastMessage != null) {
      chatController.remove(lastMessage);
    }
    emit(state.copyWith(promptResponseState: PromptResponseState.ready));
  }

  // Answer regeneration handler
  void _handleRegenerateAnswer(
    String id,
    PredefinedFormat? format,
    AIModelPB? model,
    Emitter<ChatState> emit,
  ) {
    _messageHandler.clearRelatedQuestions();
    _regenerateAnswer(id, format, model);
    lastSentMessage = null;

    isFetchingRelatedQuestions = false;
    shouldFetchRelatedQuestions = false;

    emit(
      state.copyWith(
        promptResponseState: PromptResponseState.sendingQuestion,
      ),
    );
  }

  // Related questions handler
  void _handleRelatedQuestions(List<String> questions) {
    if (questions.isEmpty) {
      return;
    }

    final metadata = {
      onetimeShotType: OnetimeShotType.relatedQuestion,
      'questions': questions,
    };

    final createdAt = DateTime.now();
    final message = TextMessage(
      id: "related_question_$createdAt",
      text: '',
      metadata: metadata,
      author: const User(id: systemUserId),
      createdAt: createdAt,
    );

    chatController.insert(message);
  }

  void _startListening() {
    listener.start(
      chatMessageCallback: (pb) {
        if (isClosed) {
          return;
        }

        _messageHandler.processReceivedMessage(pb);
        final message = _messageHandler.createTextMessage(pb);
        add(ChatEvent.receiveMessage(message));
      },
      chatErrorMessageCallback: (err) {
        if (!isClosed) {
          Log.error("chat error: ${err.errorMessage}");
          add(const ChatEvent.didFinishAnswerStream());
        }
      },
      latestMessageCallback: (list) {
        if (!isClosed) {
          final messages =
              list.messages.map(_messageHandler.createTextMessage).toList();
          add(ChatEvent.didLoadLatestMessages(messages));
        }
      },
      prevMessageCallback: (list) {
        if (!isClosed) {
          final messages =
              list.messages.map(_messageHandler.createTextMessage).toList();
          add(ChatEvent.didLoadPreviousMessages(messages, list.hasMore));
        }
      },
      finishStreamingCallback: () async {
        if (isClosed) {
          return;
        }

        add(const ChatEvent.didFinishAnswerStream());
        unawaited(_fetchRelatedQuestionsIfNeeded());
      },
    );
  }

  // Split method to handle related questions
  Future<void> _fetchRelatedQuestionsIfNeeded() async {
    // Don't fetch related questions if conditions aren't met
    if (_streamManager.answerStream == null ||
        lastSentMessage == null ||
        !shouldFetchRelatedQuestions) {
      return;
    }

    final payload = ChatMessageIdPB(
      chatId: chatId,
      messageId: lastSentMessage!.messageId,
    );

    isFetchingRelatedQuestions = true;
    await AIEventGetRelatedQuestion(payload).send().fold(
      (list) {
        // while fetching related questions, the user might enter a new
        // question or regenerate a previous response. In such cases, don't
        // display the relatedQuestions
        if (!isClosed && isFetchingRelatedQuestions) {
          add(
            ChatEvent.didReceiveRelatedQuestions(
              list.items.map((e) => e.content).toList(),
            ),
          );
          isFetchingRelatedQuestions = false;
        }
      },
      (err) => Log.error("Failed to get related questions: $err"),
    );
  }

  void _loadSettings() async {
    final getChatSettingsPayload =
        AIEventGetChatSettings(ChatId(value: chatId));

    await getChatSettingsPayload.send().fold(
      (settings) {
        if (!isClosed) {
          add(ChatEvent.didReceiveChatSettings(settings: settings));
        }
      },
      (err) => Log.error("Failed to load chat settings: $err"),
    );
  }

  void _loadMessages() async {
    final loadMessagesPayload = LoadNextChatMessagePB(
      chatId: chatId,
      limit: Int64(10),
    );

    await AIEventLoadNextMessage(loadMessagesPayload).send().fold(
      (list) {
        if (!isClosed) {
          final messages =
              list.messages.map(_messageHandler.createTextMessage).toList();
          add(ChatEvent.didLoadLatestMessages(messages));
        }
      },
      (err) => Log.error("Failed to load messages: $err"),
    );
  }

  void _loadPreviousMessagesIfNeeded() {
    if (isLoadingPreviousMessages) {
      return;
    }

    final oldestMessage = _messageHandler.getOldestMessage();

    if (oldestMessage != null) {
      final oldestMessageId = Int64.tryParseInt(oldestMessage.id);
      if (oldestMessageId == null) {
        Log.error("Failed to parse message_id: ${oldestMessage.id}");
        return;
      }
      isLoadingPreviousMessages = true;
      _loadPreviousMessages(oldestMessageId);
    }
  }

  void _loadPreviousMessages(Int64? beforeMessageId) {
    final payload = LoadPrevChatMessagePB(
      chatId: chatId,
      limit: Int64(10),
      beforeMessageId: beforeMessageId,
    );
    AIEventLoadPrevMessage(payload).send();
  }

  // Refactored method to handle message streaming
  Future<void> _startStreamingMessage(
    String message,
    PredefinedFormat? format,
    Map<String, dynamic>? metadata,
  ) async {
    // Prepare streams
    await _streamManager.prepareStreams();

    // Create and add question message
    final questionStreamMessage = _messageHandler.createQuestionStreamMessage(
      _streamManager.questionStream!,
      metadata,
    );
    add(ChatEvent.receiveMessage(questionStreamMessage));

    // Send stream request
    await _streamManager.sendStreamRequest(message, format).fold(
      (question) {
        if (!isClosed) {
          // Create and add answer stream message
          final streamAnswer = _messageHandler.createAnswerStreamMessage(
            stream: _streamManager.answerStream!,
            questionMessageId: question.messageId,
            fakeQuestionMessageId: questionStreamMessage.id,
          );

          lastSentMessage = question;
          add(const ChatEvent.finishSending());
          add(ChatEvent.receiveMessage(streamAnswer));
        }
      },
      (err) {
        if (!isClosed) {
          Log.error("Failed to send message: ${err.msg}");

          final metadata = {
            onetimeShotType: OnetimeShotType.error,
            if (err.code != ErrorCode.Internal) errorMessageTextKey: err.msg,
          };

          final error = TextMessage(
            text: '',
            metadata: metadata,
            author: const User(id: systemUserId),
            id: systemUserId,
            createdAt: DateTime.now(),
          );

          add(const ChatEvent.failedSending());
          add(ChatEvent.receiveMessage(error));
        }
      },
    );
  }

  // Refactored method to handle answer regeneration
  void _regenerateAnswer(
    String answerMessageIdString,
    PredefinedFormat? format,
    AIModelPB? model,
  ) async {
    final id = _messageHandler.temporaryMessageIDMap.entries
            .firstWhereOrNull((e) => e.value == answerMessageIdString)
            ?.key ??
        answerMessageIdString;
    final answerMessageId = Int64.tryParseInt(id);

    if (answerMessageId == null) {
      return;
    }

    await _streamManager.prepareStreams();

    await _streamManager
        .sendRegenerateRequest(
      answerMessageId,
      format,
      model,
    )
        .fold(
      (_) {
        if (!isClosed) {
          final streamAnswer = _messageHandler
              .createAnswerStreamMessage(
                stream: _streamManager.answerStream!,
                questionMessageId: answerMessageId - 1,
              )
              .copyWith(id: answerMessageIdString);

          add(ChatEvent.receiveMessage(streamAnswer));
          add(const ChatEvent.finishSending());
        }
      },
      (err) => Log.error("Failed to regenerate answer: ${err.msg}"),
    );
  }
}

@freezed
class ChatEvent with _$ChatEvent {
  // chat settings
  const factory ChatEvent.didReceiveChatSettings({
    required ChatSettingsPB settings,
  }) = _DidReceiveChatSettings;
  const factory ChatEvent.updateSelectedSources({
    required List<String> selectedSourcesIds,
  }) = _UpdateSelectedSources;

  // send message
  const factory ChatEvent.sendMessage({
    required String message,
    PredefinedFormat? format,
    Map<String, dynamic>? metadata,
  }) = _SendMessage;
  const factory ChatEvent.finishSending() = _FinishSendMessage;
  const factory ChatEvent.failedSending() = _FailSendMessage;

  // regenerate
  const factory ChatEvent.regenerateAnswer(
    String id,
    PredefinedFormat? format,
    AIModelPB? model,
  ) = _RegenerateAnswer;

  // streaming answer
  const factory ChatEvent.stopStream() = _StopStream;
  const factory ChatEvent.didFinishAnswerStream() = _DidFinishAnswerStream;

  // receive message
  const factory ChatEvent.receiveMessage(Message message) = _ReceiveMessage;

  // loading messages
  const factory ChatEvent.didLoadLatestMessages(List<Message> messages) =
      _DidLoadMessages;
  const factory ChatEvent.loadPreviousMessages() = _LoadPreviousMessages;
  const factory ChatEvent.didLoadPreviousMessages(
    List<Message> messages,
    bool hasMore,
  ) = _DidLoadPreviousMessages;

  // related questions
  const factory ChatEvent.didReceiveRelatedQuestions(
    List<String> questions,
  ) = _DidReceiveRelatedQueston;

  const factory ChatEvent.deleteMessage(Message message) = _DeleteMessage;

  const factory ChatEvent.onAIFollowUp(AIFollowUpData followUpData) =
      _OnAIFollowUp;
}

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required LoadChatMessageStatus loadingState,
    required PromptResponseState promptResponseState,
    required bool clearErrorMessages,
  }) = _ChatState;

  factory ChatState.initial() => const ChatState(
        loadingState: LoadChatMessageStatus.loading,
        promptResponseState: PromptResponseState.ready,
        clearErrorMessages: false,
      );
}

bool isOtherUserMessage(Message message) {
  return message.author.id != aiResponseUserId &&
      message.author.id != systemUserId &&
      !message.author.id.startsWith("streamId:");
}
