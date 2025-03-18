import 'package:appflowy/workspace/application/sidebar/folder/folder_v2_bloc_event.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_v2_bloc_state.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
}
