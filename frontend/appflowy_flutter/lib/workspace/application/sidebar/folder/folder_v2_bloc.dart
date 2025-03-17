import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderV2Bloc extends Bloc<FolderV2Event, FolderV2State> {
  FolderV2Bloc({
    required this.workspaceId,
  }) : super(const FolderV2Initial()) {
    on<FolderV2GetView>(_onGetView);
  }

  final String workspaceId;

  Future<void> _onGetView(
    FolderV2GetView event,
    Emitter<FolderV2State> emit,
  ) async {
    emit(const FolderV2Loading());

    final request = GetWorkspaceViewPB(value: workspaceId);
    final response = await FolderEventGetWorkspaceFolder(request).send();
    response.fold(
      (view) => emit(FolderV2Loaded(view: view)),
      (error) => emit(FolderV2Error(error)),
    );
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
    required this.view,
  });

  final FolderViewPB view;

  @override
  List<Object?> get props => [view];
}

final class FolderV2Error extends FolderV2State {
  const FolderV2Error(this.error);

  final FlowyError error;

  @override
  List<Object?> get props => [error];
}
