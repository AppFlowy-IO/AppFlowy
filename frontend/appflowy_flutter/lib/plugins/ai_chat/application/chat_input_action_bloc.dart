import 'dart:async';

import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_input_action_bloc.freezed.dart';

class ChatInputActionBloc
    extends Bloc<ChatInputActionEvent, ChatInputActionState> {
  ChatInputActionBloc() : super(const ChatInputActionState()) {
    on<ChatInputActionEvent>(_handleEvent);
  }

  Future<void> _handleEvent(
    ChatInputActionEvent event,
    Emitter<ChatInputActionState> emit,
  ) async {
    await event.when(
      started: () async {
        await ViewBackendService.getAllViews().fold(
          (result) {
            final views = result.items
                .where(
                  (v) =>
                      v.layout.isDocumentView &&
                      !v.isSpace &&
                      v.parentViewId.isNotEmpty,
                )
                .toList();
            if (!isClosed) {
              add(ChatInputActionEvent.refreshViews(views));
            }
          },
          Log.error,
        );
      },
      refreshViews: (List<ViewPB> views) {
        final List<ViewPB> pages = _filterPages(
          views,
          state.selectedPages,
          state.filter,
        );
        emit(
          state.copyWith(
            views: views,
            pages: pages,
            indicator: const ChatActionMenuIndicator.ready(),
          ),
        );
      },
      filter: (String filter) {
        Log.debug("Filter chat input pages: $filter");
        final List<ViewPB> pages = _filterPages(
          state.views,
          state.selectedPages,
          filter,
        );

        emit(state.copyWith(pages: pages, filter: filter));
      },
      handleKeyEvent: (PhysicalKeyboardKey physicalKey) {
        emit(
          state.copyWith(
            keyboardKey: ChatInputKeyboardEvent(physicalKey: physicalKey),
          ),
        );
      },
      addPage: (page) {
        if (state.selectedPages.any((p) => p.id == page.id)) {
          return;
        }
        final List<ViewPB> pages = _filterPages(
          state.views,
          state.selectedPages,
          state.filter,
        );
        emit(
          state.copyWith(
            pages: pages,
            selectedPages: [...state.selectedPages, page],
          ),
        );
      },
      removePage: (String text) {
        final selectedPages = [
          ...state.selectedPages.where((t) => !text.contains(t.name)),
        ];

        final List<ViewPB> allPages = _filterPages(
          state.views,
          state.selectedPages,
          state.filter,
        );

        emit(
          state.copyWith(
            selectedPages: selectedPages,
            pages: allPages,
          ),
        );
      },
      clear: () {
        emit(
          state.copyWith(
            selectedPages: [],
            filter: "",
          ),
        );
      },
    );
  }
}

List<ViewPB> _filterPages(
  List<ViewPB> views,
  List<ViewPB> selectedPages,
  String filter,
) {
  final pages = views.where((page) => !selectedPages.contains(page)).toList();

  if (filter.isNotEmpty) {
    pages.retainWhere(
      (v) => v.name.toLowerCase().contains(filter.toLowerCase()),
    );
  }

  return pages;
}

@freezed
class ChatInputActionEvent with _$ChatInputActionEvent {
  const factory ChatInputActionEvent.started() = _Started;
  const factory ChatInputActionEvent.refreshViews(List<ViewPB> views) =
      _RefreshViews;
  const factory ChatInputActionEvent.filter(String filter) = _Filter;
  const factory ChatInputActionEvent.handleKeyEvent(
    PhysicalKeyboardKey keyboardKey,
  ) = _HandleKeyEvent;
  const factory ChatInputActionEvent.addPage(ViewPB page) = _AddPage;
  const factory ChatInputActionEvent.removePage(String text) = _RemovePage;
  const factory ChatInputActionEvent.clear() = _Clear;
}

@freezed
class ChatInputActionState with _$ChatInputActionState {
  const factory ChatInputActionState({
    @Default([]) List<ViewPB> views,
    @Default([]) List<ViewPB> pages,
    @Default([]) List<ViewPB> selectedPages,
    @Default("") String filter,
    ChatInputKeyboardEvent? keyboardKey,
    @Default(ChatActionMenuIndicator.loading())
    ChatActionMenuIndicator indicator,
  }) = _ChatInputActionState;
}

class ChatInputKeyboardEvent extends Equatable {
  ChatInputKeyboardEvent({required this.physicalKey});

  final PhysicalKeyboardKey physicalKey;
  final int timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [timestamp];
}

@freezed
class ChatActionMenuIndicator with _$ChatActionMenuIndicator {
  const factory ChatActionMenuIndicator.ready() = _Ready;
  const factory ChatActionMenuIndicator.loading() = _Loading;
}
