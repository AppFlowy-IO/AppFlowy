import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:equatable/equatable.dart';
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
    required this.workspaceId,
  }) : super(const FolderV2Initial()) {
    on<FolderV2GetView>(_onGetView);
    on<FolderV2SwitchCurrentSpace>(_onSwitchCurrentSpace);
    on<FolderV2ExpandSpace>(_onExpandSpace);
  }

  final String workspaceId;

  Future<void> _onGetView(
    FolderV2GetView event,
    Emitter<FolderV2State> emit,
  ) async {
    emit(const FolderV2Loading());

    final request = GetWorkspaceFolderViewPB(
      workspaceId: workspaceId,
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
}

sealed class FolderV2Event extends Equatable {
  const FolderV2Event();

  @override
  List<Object?> get props => [];
}

final class FolderV2GetView extends FolderV2Event {
  const FolderV2GetView();
}

final class FolderV2SwitchCurrentSpace extends FolderV2Event {
  const FolderV2SwitchCurrentSpace({
    required this.spaceId,
  });

  final String spaceId;

  @override
  List<Object?> get props => [spaceId];
}

final class FolderV2ExpandSpace extends FolderV2Event {
  const FolderV2ExpandSpace({
    required this.isExpanded,
  });

  final bool isExpanded;

  @override
  List<Object?> get props => [isExpanded];
}

sealed class FolderV2State extends Equatable {
  const FolderV2State();

  @override
  List<Object?> get props => [];
}

final class FolderV2Initial extends FolderV2State {
  const FolderV2Initial();

  @override
  List<Object?> get props => [];
}

class FolderV2Loading extends FolderV2State {
  const FolderV2Loading();

  @override
  List<Object?> get props => [];
}

class FolderV2Loaded extends FolderV2State {
  const FolderV2Loaded({
    required this.folderView,
    required this.currentSpace,
    this.isExpanded = true,
  });

  final FolderViewPB folderView;
  final FolderViewPB currentSpace;
  final bool isExpanded;

  @override
  List<Object?> get props => [folderView, currentSpace, isExpanded];
}

final class FolderV2Error extends FolderV2State {
  const FolderV2Error(this.error);

  final FlowyError error;

  @override
  List<Object?> get props => [error];
}
