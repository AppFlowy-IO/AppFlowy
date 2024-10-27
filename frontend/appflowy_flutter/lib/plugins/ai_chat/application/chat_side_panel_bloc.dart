import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_side_panel_bloc.freezed.dart';

const double kDefaultSidePanelWidth = 500;

class ChatSidePanelBloc extends Bloc<ChatSidePanelEvent, ChatSidePanelState> {
  ChatSidePanelBloc({
    required this.chatId,
  }) : super(const ChatSidePanelState()) {
    on<ChatSidePanelEvent>(
      (event, emit) async {
        await event.when(
          selectedMetadata: (ChatMessageRefSource metadata) async {
            emit(
              state.copyWith(
                metadata: metadata,
                indicator: const ChatSidePanelIndicator.loading(),
              ),
            );
            unawaited(
              ViewBackendService.getView(metadata.id).then(
                (result) {
                  result.fold((view) {
                    if (!isClosed) {
                      add(ChatSidePanelEvent.open(view));
                    }
                  }, (err) {
                    Log.error("Failed to get view: $err");
                  });
                },
              ),
            );
          },
          close: () {
            emit(state.copyWith(metadata: null, isShowPanel: false));
          },
          open: (ViewPB view) {
            emit(
              state.copyWith(
                indicator: ChatSidePanelIndicator.ready(view),
                isShowPanel: true,
              ),
            );
          },
        );
      },
    );
  }

  final String chatId;
}

@freezed
class ChatSidePanelEvent with _$ChatSidePanelEvent {
  const factory ChatSidePanelEvent.selectedMetadata(
    ChatMessageRefSource metadata,
  ) = _SelectedMetadata;
  const factory ChatSidePanelEvent.close() = _Close;
  const factory ChatSidePanelEvent.open(ViewPB view) = _Open;
}

@freezed
class ChatSidePanelState with _$ChatSidePanelState {
  const factory ChatSidePanelState({
    ChatMessageRefSource? metadata,
    @Default(ChatSidePanelIndicator.loading()) ChatSidePanelIndicator indicator,
    @Default(false) bool isShowPanel,
  }) = _ChatSidePanelState;
}

@freezed
class ChatSidePanelIndicator with _$ChatSidePanelIndicator {
  const factory ChatSidePanelIndicator.ready(ViewPB view) = _Ready;
  const factory ChatSidePanelIndicator.loading() = _Loading;
}
