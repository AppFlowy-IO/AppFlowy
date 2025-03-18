import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
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

final class FolderV2CreatePage extends FolderV2Event {
  const FolderV2CreatePage({
    required this.payload,
  });

  final CreatePagePayloadPB payload;

  @override
  List<Object?> get props => [payload];
}

final class FolderV2UpdatePage extends FolderV2Event {
  const FolderV2UpdatePage({
    required this.viewId,
    this.name,
    this.icon,
    this.isLocked,
  });

  final String viewId;
  final String? name;
  final ViewIconPB? icon;
  final bool? isLocked;

  @override
  List<Object?> get props => [viewId, name, icon, isLocked];
}

final class FolderV2MovePageToTrash extends FolderV2Event {
  const FolderV2MovePageToTrash({
    required this.payload,
  });

  final MovePageToTrashPayloadPB payload;

  @override
  List<Object?> get props => [payload];
}

final class FolderV2RestorePageFromTrash extends FolderV2Event {
  const FolderV2RestorePageFromTrash({
    required this.payload,
  });

  final RestorePageFromTrashPayloadPB payload;

  @override
  List<Object?> get props => [payload];
}

final class FolderV2CreateSpace extends FolderV2Event {
  const FolderV2CreateSpace({
    required this.payload,
  });

  final CreateSpacePayloadPB payload;

  @override
  List<Object?> get props => [payload];
}

final class FolderV2UpdateSpace extends FolderV2Event {
  const FolderV2UpdateSpace({
    required this.payload,
  });

  final UpdateSpacePayloadPB payload;

  @override
  List<Object?> get props => [payload];
}

final class FolderV2DuplicatePage extends FolderV2Event {
  const FolderV2DuplicatePage({
    required this.payload,
  });

  final DuplicatePagePayloadPB payload;

  @override
  List<Object?> get props => [payload];
}

final class FolderV2MovePage extends FolderV2Event {
  const FolderV2MovePage({
    required this.payload,
  });

  final MovePagePayloadPB payload;

  @override
  List<Object?> get props => [payload];
}
