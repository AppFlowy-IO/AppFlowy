import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_select_message_bloc.freezed.dart';

class ChatSelectMessageBloc
    extends Bloc<ChatSelectMessageEvent, ChatSelectMessageState> {
  ChatSelectMessageBloc({required this.viewNotifier})
      : super(ChatSelectMessageState.initial()) {
    _dispatch();
  }

  final ViewPluginNotifier viewNotifier;

  void _dispatch() {
    on<ChatSelectMessageEvent>(
      (event, emit) {
        event.when(
          enableStartSelectingMessages: () {
            emit(state.copyWith(enabled: true));
          },
          toggleSelectingMessages: () {
            if (state.isSelectingMessages) {
              emit(
                state.copyWith(
                  isSelectingMessages: false,
                  selectedMessages: [],
                ),
              );
            } else {
              emit(state.copyWith(isSelectingMessages: true));
            }
          },
          toggleSelectMessage: (Message message) {
            if (state.selectedMessages.contains(message)) {
              emit(
                state.copyWith(
                  selectedMessages: state.selectedMessages
                      .where((m) => m != message)
                      .toList(),
                ),
              );
            } else {
              emit(
                state.copyWith(
                  selectedMessages: [...state.selectedMessages, message],
                ),
              );
            }
          },
          selectAllMessages: (List<Message> messages) {
            final filtered = messages.where(isAIMessage).toList();
            emit(state.copyWith(selectedMessages: filtered));
          },
          unselectAllMessages: () {
            emit(state.copyWith(selectedMessages: const []));
          },
          reset: () {
            emit(
              state.copyWith(
                isSelectingMessages: false,
                selectedMessages: [],
              ),
            );
          },
        );
      },
    );
  }

  bool isMessageSelected(String messageId) =>
      state.selectedMessages.any((m) => m.id == messageId);

  bool isAIMessage(Message message) {
    return message.author.id == aiResponseUserId ||
        message.author.id == systemUserId ||
        message.author.id.startsWith("streamId:");
  }
}

@freezed
class ChatSelectMessageEvent with _$ChatSelectMessageEvent {
  const factory ChatSelectMessageEvent.enableStartSelectingMessages() =
      _EnableStartSelectingMessages;
  const factory ChatSelectMessageEvent.toggleSelectingMessages() =
      _ToggleSelectingMessages;
  const factory ChatSelectMessageEvent.toggleSelectMessage(Message message) =
      _ToggleSelectMessage;
  const factory ChatSelectMessageEvent.selectAllMessages(
    List<Message> messages,
  ) = _SelectAllMessages;
  const factory ChatSelectMessageEvent.unselectAllMessages() =
      _UnselectAllMessages;
  const factory ChatSelectMessageEvent.reset() = _Reset;
}

@freezed
class ChatSelectMessageState with _$ChatSelectMessageState {
  const factory ChatSelectMessageState({
    required bool isSelectingMessages,
    required List<Message> selectedMessages,
    required bool enabled,
  }) = _ChatSelectMessageState;

  factory ChatSelectMessageState.initial() => const ChatSelectMessageState(
        enabled: false,
        isSelectingMessages: false,
        selectedMessages: [],
      );
}
