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
    if (state is! FolderV2Loaded) {
      emit(const FolderV2Loading());
    }

    final request = GetWorkspaceFolderViewPB(
      workspaceId: currentWorkspaceId,
      depth: 10,
    );

    final response = await FolderEventGetWorkspaceFolder(request).send();
    response.fold(
      (folderView) {
        FolderViewPB currentSpace;
        if (state is FolderV2Loaded) {
          currentSpace = folderView.children.firstWhere(
            (e) => e.viewId == (state as FolderV2Loaded).currentSpace.viewId,
          );
        } else {
          currentSpace = folderView.children.first;
        }
        emit(
          FolderV2Loaded(
            folderView: folderView,
            currentSpace: currentSpace,
          ),
        );
      },
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
    final request = CreatePagePayloadPB(
      workspaceId: currentWorkspaceId,
      name: event.name,
      layout: event.layout,
      parentViewId: event.parentViewId,
    );
    final response = await FolderEventCreatePage(request).send();
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
    final payload = UpdatePagePayloadPB(
      workspaceId: currentWorkspaceId,
      viewId: event.viewId,
      name: event.name,
      icon: event.icon,
      isLocked: event.isLocked,
    );
    final response = await FolderEventUpdatePage(payload).send();
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
    final request = DuplicatePagePayloadPB(
      workspaceId: currentWorkspaceId,
      viewId: event.viewId,
      suffix: event.suffix,
    );
    final response = await FolderEventDuplicatePage(request).send();
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
    final request = MovePagePayloadPB(
      workspaceId: currentWorkspaceId,
      viewId: event.viewId,
      newParentViewId: event.newParentViewId,
      prevViewId: event.prevViewId,
    );
    final response = await FolderEventMovePage(request).send();
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
    final request = MovePageToTrashPayloadPB(
      workspaceId: currentWorkspaceId,
      viewId: event.viewId,
    );
    final response = await FolderEventMovePageToTrash(request).send();
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
    final request = RestorePageFromTrashPayloadPB(
      workspaceId: currentWorkspaceId,
      viewId: event.viewId,
    );
    final response = await FolderEventRestorePageFromTrash(request).send();
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
    final request = CreateSpacePayloadPB(
      workspaceId: currentWorkspaceId,
      name: event.name,
      spacePermission: event.spacePermission,
      spaceIcon: event.spaceIcon,
      spaceIconColor: event.spaceIconColor,
    );
    final response = await FolderEventCreateSpace(request).send();
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
    final request = UpdateSpacePayloadPB(
      workspaceId: currentWorkspaceId,
      spaceId: event.spaceId,
      name: event.name,
      spacePermission: event.spacePermission,
      spaceIcon: event.spaceIcon,
      spaceIconColor: event.spaceIconColor,
    );
    final response = await FolderEventUpdateSpace(request).send();
    response.fold(
      // todo: update the in memory data
      (folderView) => add(const FolderV2GetFolderViews()),
      (error) => emit(FolderV2Error(error)),
    );
  }
}
