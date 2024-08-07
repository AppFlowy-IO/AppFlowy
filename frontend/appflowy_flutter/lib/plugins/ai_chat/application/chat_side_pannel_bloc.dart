import 'dart:async';

import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_side_pannel_bloc.freezed.dart';

const double kDefaultSidePannelWidth = 500;

class ChatSidePannelBloc
    extends Bloc<ChatSidePannelEvent, ChatSidePannelState> {
  ChatSidePannelBloc({
    required this.chatId,
  }) : super(const ChatSidePannelState()) {
    on<ChatSidePannelEvent>(
      (event, emit) async {
        await event.when(
          selectedMetadata: (ChatMessageMetadata metadata) async {
            emit(
              state.copyWith(
                metadata: metadata,
                indicator: const ChatSidePannelIndicator.loading(),
              ),
            );
            unawaited(
              ViewBackendService.getView(metadata.id).then(
                (result) {
                  result.fold((view) {
                    if (!isClosed) {
                      add(ChatSidePannelEvent.open(view));
                    }
                  }, (err) {
                    Log.error("Failed to get view: $err");
                  });
                },
              ),
            );
          },
          close: () {
            emit(state.copyWith(metadata: null, isShowPannel: false));
          },
          open: (ViewPB view) {
            emit(
              state.copyWith(
                indicator: ChatSidePannelIndicator.ready(view),
                isShowPannel: true,
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
class ChatSidePannelEvent with _$ChatSidePannelEvent {
  const factory ChatSidePannelEvent.selectedMetadata(
    ChatMessageMetadata metadata,
  ) = _SelectedMetadata;
  const factory ChatSidePannelEvent.close() = _Close;
  const factory ChatSidePannelEvent.open(ViewPB view) = _Open;
}

@freezed
class ChatSidePannelState with _$ChatSidePannelState {
  const factory ChatSidePannelState({
    ChatMessageMetadata? metadata,
    @Default(ChatSidePannelIndicator.loading())
    ChatSidePannelIndicator indicator,
    @Default(false) bool isShowPannel,
  }) = _ChatSidePannelState;
}

@freezed
class ChatSidePannelIndicator with _$ChatSidePannelIndicator {
  const factory ChatSidePannelIndicator.ready(ViewPB view) = _Ready;
  const factory ChatSidePannelIndicator.loading() = _Loading;
}
