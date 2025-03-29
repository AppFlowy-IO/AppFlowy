import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:equatable/equatable.dart';

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
