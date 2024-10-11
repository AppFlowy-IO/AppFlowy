import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_bloc.freezed.dart';

typedef MentionPageStatus = (ViewPB? view, bool isInTrash, bool isDeleted);

class MentionPageBloc extends Bloc<MentionPageEvent, MentionPageState> {
  MentionPageBloc({
    required this.pageId,
    this.blockId,
  }) : super(MentionPageState.initial()) {
    on<MentionPageEvent>((event, emit) async {
      await event.when(
        initial: () async {
          final (view, isInTrash, isDeleted) = await _fetchView(pageId);
          emit(
            state.copyWith(
              view: view,
              // todo: support fetch the block content from the view
              blockContent: view?.name ?? '',
              isLoading: false,
              isInTrash: isInTrash,
              isDeleted: isDeleted,
            ),
          );

          if (view != null) {
            _startListeningView();
          }
        },
        didUpdateBlockContent: (content) {
          emit(
            state.copyWith(
              blockContent: content,
            ),
          );
        },
        didUpdateViewStatus: (mentionPageStatus) {
          emit(
            state.copyWith(
              view: mentionPageStatus.$1,
              isInTrash: mentionPageStatus.$2,
              isDeleted: mentionPageStatus.$3,
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
  final String? blockId;

  ViewListener? _viewListener;

  void _startListeningView() {
    _viewListener = ViewListener(viewId: pageId)
      ..start(
        onViewUpdated: (view) {
          add(
            MentionPageEvent.didUpdateViewStatus(
              (view, false, false),
            ),
          );
        },
        onViewMoveToTrash: (view) {
          add(
            MentionPageEvent.didUpdateViewStatus(
              (state.view, true, false),
            ),
          );
        },
        onViewDeleted: (view) {
          add(
            const MentionPageEvent.didUpdateViewStatus(
              (null, false, true),
            ),
          );
        },
      );
  }

  Future<MentionPageStatus> _fetchView(String pageId) async {
    // Try to fetch the view from the main storage
    final view = await ViewBackendService.getView(pageId).then(
      (value) => value.toNullable(),
    );

    if (view != null) {
      return (view, false, false);
    }

    // if the view is not found, try to fetch from trash
    final trashViews = await TrashService().readTrash();
    final trash = trashViews.fold(
      (l) => l.items.firstWhereOrNull((element) => element.id == pageId),
      (r) => null,
    );
    if (trash != null) {
      final trashView = ViewPB()
        ..id = trash.id
        ..name = trash.name;
      return (trashView, true, false);
    }

    Log.info('No view found for page $pageId');
    return (null, false, true);
  }
}

@freezed
class MentionPageEvent with _$MentionPageEvent {
  const factory MentionPageEvent.initial() = _Initial;
  const factory MentionPageEvent.didUpdateBlockContent(
    String content,
  ) = _DidUpdateBlockContent;
  const factory MentionPageEvent.didUpdateViewStatus(MentionPageStatus status) =
      _DidUpdateViewStatus;
}

@freezed
class MentionPageState with _$MentionPageState {
  const factory MentionPageState({
    required bool isLoading,
    required bool isInTrash,
    required bool isDeleted,
    // non-null case:
    // - page is found
    // - page is in trash
    // null case:
    // - page is deleted
    required ViewPB? view,
    // the plain text content of the block
    // it doesn't contain any formatting
    required String blockContent,
  }) = _MentionPageState;

  factory MentionPageState.initial() => const MentionPageState(
        isLoading: true,
        isInTrash: false,
        isDeleted: false,
        blockContent: '',
        view: null,
      );
}
