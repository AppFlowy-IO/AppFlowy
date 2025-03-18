import 'package:equatable/equatable.dart';

sealed class FolderV2Event extends Equatable {
  const FolderV2Event();

  @override
  List<Object?> get props => [];
}

final class FolderV2GetFolderViews extends FolderV2Event {
  const FolderV2GetFolderViews();
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

final class FolderV2ReloadFolderViews extends FolderV2Event {
  const FolderV2ReloadFolderViews({
    this.workspaceId,
  });

  final String? workspaceId;

  @override
  List<Object?> get props => [workspaceId];
}
