import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_bloc.freezed.dart';

class MentionBloc extends Bloc<MentionEvent, MentionState> {
  MentionBloc({
    required this.pageId,
    this.blockId,
  }) : super(MentionState.initial()) {
    on<MentionEvent>((event, emit) async {
      await event.when(
        initial: () async {
          final view = await _fetchView(pageId);
          if (view == null) {
            emit(
              state.copyWith(
                isLoading: false,
                isDeleted: true,
                content: '',
              ),
            );
          } else {
            emit(
              state.copyWith(
                view: view,
                content: view.name,
                isLoading: false,
                isInTrash: false,
                isDeleted: false,
              ),
            );

            _startListeningView();
          }
        },
        didUpdateBlockContent: (content) {
          emit(
            state.copyWith(
              content: content,
            ),
          );
        },
        didUpdateViewStatus: (view, isInTrash, isDeleted) {
          emit(
            state.copyWith(
              view: view,
              isInTrash: isInTrash,
              isDeleted: isDeleted,
            ),
          );
        },
      );
    });
  }

  @override
  Future<void> close() {
    _viewListener.stop();
    return super.close();
  }

  final String pageId;
  final String? blockId;

  late final ViewListener _viewListener;

  void _startListeningView() {
    _viewListener = ViewListener(viewId: pageId)
      ..start(
        onViewUpdated: (view) {
          add(
            MentionEvent.didUpdateViewStatus(
              view,
              false,
              false,
            ),
          );
        },
        onViewMoveToTrash: (view) {
          add(
            MentionEvent.didUpdateViewStatus(
              state.view,
              true,
              false,
            ),
          );
        },
        onViewDeleted: (view) {
          add(
            MentionEvent.didUpdateViewStatus(
              state.view,
              false,
              true,
            ),
          );
        },
      );
  }

  Future<ViewPB?> _fetchView(String pageId) async {
    final view = await ViewBackendService.getView(pageId).then(
      (value) => value.toNullable(),
    );

    if (view == null) {
      // try to fetch from trash
      final trashViews = await TrashService().readTrash();
      final trash = trashViews.fold(
        (l) => l.items.firstWhereOrNull((element) => element.id == pageId),
        (r) => null,
      );
      if (trash != null) {
        return ViewPB()
          ..id = trash.id
          ..name = trash.name;
      }
    }

    return view;
  }
}

@freezed
class MentionEvent with _$MentionEvent {
  const factory MentionEvent.initial() = _Initial;
  const factory MentionEvent.didUpdateBlockContent(
    String content,
  ) = _DidUpdateBlockContent;
  const factory MentionEvent.didUpdateViewStatus(
    ViewPB? view,
    bool isInTrash,
    bool isDeleted,
  ) = _DidUpdateViewStatus;
}

@freezed
class MentionState with _$MentionState {
  const factory MentionState({
    required bool isLoading,
    required bool isInTrash,
    required bool isDeleted,
    required String content,
    required ViewPB? view,
  }) = _MentionState;

  factory MentionState.initial() => const MentionState(
        isLoading: true,
        isInTrash: false,
        isDeleted: false,
        content: '',
        view: null,
      );
}
