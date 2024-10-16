import 'dart:async';

import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_sub_page_bloc.freezed.dart';

class MentionSubPageBloc
    extends Bloc<MentionSubPageEvent, MentionSubPageState> {
  MentionSubPageBloc({
    required this.pageId,
  }) : super(MentionSubPageState.initial()) {
    on<MentionSubPageEvent>((event, emit) async {
      await event.when(
        initial: () async {
          final (view, isInTrash, isDeleted) =
              await ViewBackendService.getMentionPageStatus(pageId);
          emit(
            state.copyWith(
              view: view,
              isLoading: false,
              isInTrash: isInTrash,
              isDeleted: isDeleted,
            ),
          );

          if (view != null) {
            _startListeningView();
          }
        },
        didUpdateViewStatus: (view, isInTrash, isDeleted) {
          emit(
            state.copyWith(
              view: view,
              isInTrash: isInTrash ?? state.isInTrash,
              isDeleted: isDeleted ?? state.isDeleted,
            ),
          );
        },
      );
    });
  }

  @override
  Future<void> close() {
    _viewListener?.stop();
    return super.close();
  }

  final String pageId;
  ViewListener? _viewListener;

  void _startListeningView() {
    _viewListener = ViewListener(viewId: pageId)
      ..start(
        onViewUpdated: (view) {
          add(MentionSubPageEvent.didUpdateViewStatus(view: view));
        },
        onViewMoveToTrash: (_) {
          add(const MentionSubPageEvent.didUpdateViewStatus(isInTrash: true));
        },
        onViewDeleted: (_) {
          add(const MentionSubPageEvent.didUpdateViewStatus(isDeleted: true));
        },
      );
  }
}

@freezed
class MentionSubPageEvent with _$MentionSubPageEvent {
  const factory MentionSubPageEvent.initial() = _Initial;
  const factory MentionSubPageEvent.didUpdateViewStatus({
    @Default(null) ViewPB? view,
    @Default(null) bool? isInTrash,
    @Default(null) bool? isDeleted,
  }) = _DidUpdateViewStatus;
}

@freezed
class MentionSubPageState with _$MentionSubPageState {
  const factory MentionSubPageState({
    required bool isLoading,
    required bool isInTrash,
    required bool isDeleted,
    // non-null case:
    // - page is found
    // - page is in trash
    // null case:
    // - page is deleted
    required ViewPB? view,
  }) = _MentionSubPageState;

  factory MentionSubPageState.initial() => const MentionSubPageState(
        isLoading: true,
        isInTrash: false,
        isDeleted: false,
        view: null,
      );
}
