import 'dart:async';

import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_input_action_control.dart';

part 'chat_input_action_bloc.freezed.dart';

class ChatInputActionBloc
    extends Bloc<ChatInputActionEvent, ChatInputActionState> {
  ChatInputActionBloc({required this.chatId})
      : super(const ChatInputActionState()) {
    on<ChatInputActionEvent>(_handleEvent);
  }

  final String chatId;

  Future<void> _handleEvent(
    ChatInputActionEvent event,
    Emitter<ChatInputActionState> emit,
  ) async {
    await event.when(
      started: () async {
        unawaited(
          ViewBackendService.getAllViews().then(
            (result) {
              final views = result
                      .toNullable()
                      ?.items
                      .where(
                        (v) =>
                            v.layout.isDocumentView &&
                            !v.isSpace &&
                            v.parentViewId.isNotEmpty,
                      )
                      .toList() ??
                  [];
              if (!isClosed) {
                add(ChatInputActionEvent.refreshViews(views));
              }
            },
          ),
        );
      },
      refreshViews: (List<ViewPB> views) {
        final List<ViewActionPage> pages = _filterPages(
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
        final List<ViewActionPage> pages = _filterPages(
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
      addPage: (ChatInputActionPage page) {
        if (!state.selectedPages.any((p) => p.pageId == page.pageId)) {
          final List<ViewActionPage> pages = _filterPages(
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
        }
      },
      removePage: (String text) {
        final List<ChatInputActionPage> selectedPages =
            List.from(state.selectedPages);
        selectedPages.retainWhere((t) => !text.contains(t.title));

        final List<ViewActionPage> allPages = _filterPages(
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
    );
  }
}

List<ViewActionPage> _filterPages(
  List<ViewPB> views,
  List<ChatInputActionPage> selectedPages,
  String filter,
) {
  final pages = views
      .map(
        (v) => ViewActionPage(view: v),
      )
      .toList();

  pages.retainWhere((page) {
    return !selectedPages.contains(page);
  });

  if (filter.isEmpty) {
    return pages;
  }

  return pages
      .where(
        (v) => v.title.toLowerCase().contains(filter.toLowerCase()),
      )
      .toList();
}

class ViewActionPage extends ChatInputActionPage {
  ViewActionPage({required this.view});

  final ViewPB view;

  @override
  String get pageId => view.id;

  @override
  String get title => view.name;

  @override
  List<Object?> get props => [pageId];

  @override
  dynamic get page => view;

  @override
  Widget get icon => view.defaultIcon();
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
  const factory ChatInputActionEvent.addPage(ChatInputActionPage page) =
      _AddPage;
  const factory ChatInputActionEvent.removePage(String text) = _RemovePage;
}

@freezed
class ChatInputActionState with _$ChatInputActionState {
  const factory ChatInputActionState({
    @Default([]) List<ViewPB> views,
    @Default([]) List<ChatInputActionPage> pages,
    @Default([]) List<ChatInputActionPage> selectedPages,
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
