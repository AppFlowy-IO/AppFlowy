import 'package:appflowy/workspace/application/sidebar/folder/folder_v2_bloc_event.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_v2_bloc_state.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:appflowy/workspace/application/sidebar/folder/folder_v2_bloc_event.dart';
export 'package:appflowy/workspace/application/sidebar/folder/folder_v2_bloc_state.dart';

extension FolderViewPBExtension on FolderViewPB {
  ViewPB get viewPB {
    final children = this.children.map((e) => e.viewPB).toList();
    return ViewPB(
      id: viewId,
      name: name,
      icon: icon,
      layout: layout,
      createTime: createdAt,
      lastEdited: lastEditedTime,
      extra: extra,
      childViews: children,
    );
  }
}

class FolderV2Bloc extends Bloc<FolderV2Event, FolderV2State> {
  FolderV2Bloc({
    required this.currentWorkspaceId,
  }) : super(const FolderV2Initial()) {
    on<FolderV2GetFolderViews>(_onGetView);
    on<FolderV2SwitchCurrentSpace>(_onSwitchCurrentSpace);
    on<FolderV2ExpandSpace>(_onExpandSpace);
    on<FolderV2ReloadFolderViews>(_onReloadFolderViews);
    on<FolderV2CreatePage>(_onCreatePage);
    on<FolderV2UpdatePage>(_onUpdatePage);
    on<FolderV2DuplicatePage>(_onDuplicatePage);
    on<FolderV2MovePage>(_onMovePage);
    on<FolderV2MovePageToTrash>(_onMovePageToTrash);
    on<FolderV2RestorePageFromTrash>(_onRestorePageFromTrash);
    on<FolderV2CreateSpace>(_onCreateSpace);
    on<FolderV2UpdateSpace>(_onUpdateSpace);
  }

  String currentWorkspaceId;

  Future<void> _onGetView(
    FolderV2GetFolderViews event,
    Emitter<FolderV2State> emit,
  ) async {
    emit(const FolderV2Loading());

    final request = GetWorkspaceFolderViewPB(
      workspaceId: currentWorkspaceId,
      depth: 10,
    );
    final response = await FolderEventGetWorkspaceFolder(request).send();
    response.fold(
      (folderView) => emit(
        FolderV2Loaded(
          folderView: folderView,
          currentSpace: folderView.children.first,
        ),
      ),
      (error) => emit(FolderV2Error(error)),
    );
  }

  Future<void> _onSwitchCurrentSpace(
    FolderV2SwitchCurrentSpace event,
    Emitter<FolderV2State> emit,
  ) async {
    final currentState = state as FolderV2Loaded?;
    if (currentState != null) {
      emit(
        FolderV2Loaded(
          folderView: currentState.folderView,
          currentSpace: currentState.folderView.children.firstWhere(
            (e) => e.viewId == event.spaceId,
          ),
        ),
      );
    }
  }

  Future<void> _onExpandSpace(
    FolderV2ExpandSpace event,
    Emitter<FolderV2State> emit,
  ) async {
    final currentState = state as FolderV2Loaded?;
    if (currentState != null) {
      emit(
        FolderV2Loaded(
          folderView: currentState.folderView,
          currentSpace: currentState.currentSpace,
          isExpanded: event.isExpanded,
        ),
      );
    }
  }

  Future<void> _onReloadFolderViews(
    FolderV2ReloadFolderViews event,
    Emitter<FolderV2State> emit,
  ) async {
    emit(const FolderV2Loading());

    currentWorkspaceId = event.workspaceId ?? currentWorkspaceId;

    add(const FolderV2GetFolderViews());
  }

  Future<void> _onCreatePage(
    FolderV2CreatePage event,
    Emitter<FolderV2State> emit,
  ) async {
    final response = await FolderEventCreatePage(event.payload).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }

  Future<void> _onUpdatePage(
    FolderV2UpdatePage event,
    Emitter<FolderV2State> emit,
  ) async {
    final response = await FolderEventUpdatePage(event.payload).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }

  Future<void> _onDuplicatePage(
    FolderV2DuplicatePage event,
    Emitter<FolderV2State> emit,
  ) async {
    final response = await FolderEventDuplicatePage(event.payload).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }

  Future<void> _onMovePage(
    FolderV2MovePage event,
    Emitter<FolderV2State> emit,
  ) async {
    final response = await FolderEventMovePage(event.payload).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }

  Future<void> _onMovePageToTrash(
    FolderV2MovePageToTrash event,
    Emitter<FolderV2State> emit,
  ) async {
    final response = await FolderEventMovePageToTrash(event.payload).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }

  Future<void> _onRestorePageFromTrash(
    FolderV2RestorePageFromTrash event,
    Emitter<FolderV2State> emit,
  ) async {
    final response =
        await FolderEventRestorePageFromTrash(event.payload).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }

  Future<void> _onCreateSpace(
    FolderV2CreateSpace event,
    Emitter<FolderV2State> emit,
  ) async {
    final response = await FolderEventCreateSpace(event.payload).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }

  Future<void> _onUpdateSpace(
    FolderV2UpdateSpace event,
    Emitter<FolderV2State> emit,
  ) async {
    final response = await FolderEventUpdateSpace(event.payload).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }
}
