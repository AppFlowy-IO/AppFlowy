import 'dart:async';
import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:appflowy/workspace/application/workspace/workspace_sections_listener.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/folder_view_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';
import 'package:universal_platform/universal_platform.dart';

part 'space_bloc.freezed.dart';

enum SpacePermission {
  publicToAll,
  private,
}

extension SpacePermissionToViewSectionPBExtension on SpacePermission {
  SpacePermissionPB toSpacePermissionPB() {
    switch (this) {
      case SpacePermission.publicToAll:
        return SpacePermissionPB.PublicSpace;
      case SpacePermission.private:
        return SpacePermissionPB.PrivateSpace;
    }
  }
}

/// The [SpaceBloc] is responsible for
///   managing the spaces which are the top level views in the workspace.
class SpaceBloc extends Bloc<SpaceEvent, SpaceState> {
  SpaceBloc({
    required this.userProfile,
    required this.workspaceId,
  }) : super(SpaceState.initial()) {
    on<SpaceEvent>(
      (event, emit) async {
        await event.when(
          initial: (openFirstPage) async {
            this.openFirstPage = openFirstPage;

            _initial(userProfile, workspaceId);

            final spaces = await _getSpaces();

            final currentSpace = await _getLastOpenedSpace(spaces);
            final isExpanded = await _getSpaceExpandStatus(currentSpace);
            emit(
              state.copyWith(
                spaces: spaces,
                currentSpace: currentSpace,
                isExpanded: isExpanded,
                shouldShowUpgradeDialog: false,
                isInitialized: true,
              ),
            );

            if (openFirstPage) {
              if (currentSpace != null) {
                if (!isClosed) {
                  add(SpaceEvent.open(currentSpace));
                }
              }
            }
          },
          create: (
            name,
            icon,
            iconColor,
            permission,
            createNewPageByDefault,
            openAfterCreate,
          ) async {
            await _createSpace(
              name: name,
              icon: icon,
              iconColor: iconColor,
              permission: permission,
            );
          },
          delete: (space) async {
            if (state.spaces.length <= 1) {
              return;
            }

            final deletedSpace = space ?? state.currentSpace;
            if (deletedSpace == null) {
              return;
            }

            await ViewBackendService.deleteView(viewId: deletedSpace.viewId);

            Log.info(
              'delete space: ${deletedSpace.name}(${deletedSpace.viewId})',
            );
          },
          rename: (space, name) async {
            await _rename(space, name);
            add(const SpaceEvent.didReceiveSpaceUpdate());
          },
          changeIcon: (space, icon, iconColor) async {
            space ??= state.currentSpace;
            if (space == null) {
              Log.error('change icon failed, space is null');
              return;
            }

            await _workspaceService.updateSpaceIcon(
              space: space,
              icon: icon,
              iconColor: iconColor,
            );
          },
          update: (space, name, icon, iconColor, permission) async {
            space ??= state.currentSpace;
            if (space == null) {
              Log.error('update space failed, space is null');
              return;
            }

            await _workspaceService.updateSpace(
              space: space,
              name: name,
              icon: icon,
              iconColor: iconColor,
              permission: permission,
            );

            add(const SpaceEvent.didReceiveSpaceUpdate());
          },
          open: (space) async {
            await _openSpace(space);

            // don't open the page automatically on mobile
            if (UniversalPlatform.isDesktop) {
              // open the first page by default
              if (space.children.isNotEmpty) {
                final firstPage = space.children.first;
                emit(
                  state.copyWith(
                    lastCreatedPage: firstPage,
                  ),
                );
              } else {
                emit(
                  state.copyWith(
                    lastCreatedPage: FolderViewPB(),
                  ),
                );
              }
            }
          },
          expand: (space, isExpanded) async {
            await _setSpaceExpandStatus(space, isExpanded);
            emit(state.copyWith(isExpanded: isExpanded));
          },
          createPage: (name, layout, index, openAfterCreate) async {
            final parentViewId = state.currentSpace?.viewId;
            if (parentViewId == null) {
              Log.error('create page failed, parent view id is null');
              return;
            }

            await _createPage(
              parentViewId,
              name,
              layout,
            );

            add(const SpaceEvent.didReceiveSpaceUpdate());
          },
          didReceiveSpaceUpdate: () async {
            final spaces = await _getSpaces();
            emit(
              state.copyWith(
                spaces: spaces,
                currentSpace: spaces.firstWhereOrNull(
                  (e) => e.viewId == state.currentSpace?.viewId,
                ),
              ),
            );
          },
          reset: (userProfile, workspaceId, openFirstPage) async {
            if (this.workspaceId == workspaceId) {
              return;
            }

            _reset(userProfile, workspaceId);

            add(
              SpaceEvent.initial(
                openFirstPage: openFirstPage,
              ),
            );
          },
          migrate: () async {
            // deprecated
            // do nothing
          },
          switchToNextSpace: () async {
            final spaces = state.spaces;
            if (spaces.isEmpty) {
              return;
            }

            final currentSpace = state.currentSpace;
            if (currentSpace == null) {
              return;
            }
            final currentIndex = spaces.indexOf(currentSpace);
            final nextIndex = (currentIndex + 1) % spaces.length;
            final nextSpace = spaces[nextIndex];
            add(SpaceEvent.open(nextSpace));
          },
          duplicate: (space) async {
            space ??= state.currentSpace;
            if (space == null) {
              Log.error('duplicate space failed, space is null');
              return;
            }

            Log.info('duplicate space: ${space.name}(${space.viewId})');

            emit(state.copyWith(isDuplicatingSpace: true));

            await _duplicateSpace(space);

            // open the duplicated space
            add(const SpaceEvent.didReceiveSpaceUpdate());
            add(SpaceEvent.open(space));

            emit(state.copyWith(isDuplicatingSpace: false));
          },
          createSpace: (name, permission, icon, iconColor) async {
            await _createSpace(
              name: name,
              icon: icon,
              iconColor: iconColor,
              permission: permission,
            );
          },
          switchCurrentSpace: (spaceId) async {
            final spaces = state.spaces;
            final space = spaces.firstWhereOrNull((e) => e.viewId == spaceId);
            if (space == null) {
              return;
            }
            await _openSpace(space);
            emit(
              state.copyWith(currentSpace: space),
            );
          },
        );
      },
    );
  }

  late WorkspaceService _workspaceService;
  late String workspaceId;
  late UserProfilePB userProfile;
  WorkspaceSectionsListener? _listener;
  bool openFirstPage = false;

  @override
  Future<void> close() async {
    refreshNotifier.removeListener(_refresh);
    await _listener?.stop();
    _listener = null;
    return super.close();
  }

  Future<List<FolderViewPB>> _getSpaces() async {
    final response = await _workspaceService.getFolderView();
    final List<FolderViewPB> spaces = response.fold(
      (folderView) {
        return folderView.children.where((e) => e.isSpace).toList();
      },
      (error) {
        Log.error('Failed to get folder view: $error');
        return [];
      },
    );
    return spaces;
  }

  Future<void> _createSpace({
    required String name,
    required String icon,
    required String iconColor,
    required SpacePermission permission,
  }) async {
    final response = await _workspaceService.createSpace(
      name: name,
      icon: icon,
      iconColor: iconColor,
      permission: permission,
    );
    return response.fold((_) {
      Log.info('Created space: $name, icon: $icon, iconColor: $iconColor');
    }, (error) {
      Log.error('Failed to create space: $error');
    });
  }

  Future<void> _createPage(
    String parentViewId,
    String name,
    ViewLayoutPB layout,
  ) async {
    final response = await _workspaceService.createPage(
      parentViewId: parentViewId,
      name: name,
      layout: layout,
    );
    return response.fold((_) {
      Log.info('Created page: $name, layout: $layout');
    }, (error) {
      Log.error('Failed to create page: $error');
    });
  }

  Future<FolderViewPB> _rename(FolderViewPB space, String name) async {
    final response = await _workspaceService.updateSpaceName(
      space: space,
      name: name,
    );
    return response.fold((_) {
      space.freeze();
      return space.rebuild((b) => b.name = name);
    }, (error) {
      Log.error('Failed to rename space: $error');
      return space;
    });
  }

  void _initial(UserProfilePB userProfile, String workspaceId) {
    this.userProfile = userProfile;
    this.workspaceId = workspaceId;

    _workspaceService = WorkspaceService(workspaceId: workspaceId);

    refreshNotifier.addListener(_refresh);
  }

  void _refresh() {
    if (isClosed) {
      return;
    }
    add(const SpaceEvent.didReceiveSpaceUpdate());
  }

  void _reset(UserProfilePB userProfile, String workspaceId) {
    this.userProfile = userProfile;
    this.workspaceId = workspaceId;

    _workspaceService = WorkspaceService(workspaceId: workspaceId);
  }

  Future<FolderViewPB?> _getLastOpenedSpace(List<FolderViewPB> spaces) async {
    if (spaces.isEmpty) {
      return null;
    }

    final spaceId =
        await getIt<KeyValueStorage>().get(KVKeys.lastOpenedSpaceId);
    if (spaceId == null) {
      return spaces.first;
    }

    final space =
        spaces.firstWhereOrNull((e) => e.viewId == spaceId) ?? spaces.first;
    return space;
  }

  Future<void> _openSpace(FolderViewPB space) async {
    await getIt<KeyValueStorage>().set(KVKeys.lastOpenedSpaceId, space.viewId);
  }

  Future<void> _setSpaceExpandStatus(
    FolderViewPB? space,
    bool isExpanded,
  ) async {
    if (space == null) {
      return;
    }

    final result = await getIt<KeyValueStorage>().get(KVKeys.expandedViews);
    var map = {};
    if (result != null) {
      map = jsonDecode(result);
    }
    if (isExpanded) {
      // set expand status to true if it's not expanded
      map[space.viewId] = true;
    } else {
      // remove the expand status if it's expanded
      map.remove(space.viewId);
    }
    await getIt<KeyValueStorage>().set(KVKeys.expandedViews, jsonEncode(map));
  }

  Future<bool> _getSpaceExpandStatus(FolderViewPB? space) async {
    if (space == null) {
      return true;
    }

    return getIt<KeyValueStorage>().get(KVKeys.expandedViews).then((result) {
      if (result == null) {
        return true;
      }
      final map = jsonDecode(result);
      return map[space.viewId] ?? true;
    });
  }

  Future<void> _duplicateSpace(FolderViewPB space) async {
    final response = await _workspaceService.duplicateSpace(space: space);
    response.fold((newSpace) {
      Log.info('Duplicated space: ${space.name}(${space.viewId})');
    }, (error) {
      Log.error('Failed to duplicate space: $error');
    });
  }
}

@freezed
class SpaceEvent with _$SpaceEvent {
  const factory SpaceEvent.initial({
    required bool openFirstPage,
  }) = _Initial;
  const factory SpaceEvent.create({
    required String name,
    required String icon,
    required String iconColor,
    required SpacePermission permission,
    required bool createNewPageByDefault,
    required bool openAfterCreate,
  }) = _Create;
  const factory SpaceEvent.rename({
    required FolderViewPB space,
    required String name,
  }) = _Rename;
  const factory SpaceEvent.changeIcon({
    FolderViewPB? space,
    String? icon,
    String? iconColor,
  }) = _ChangeIcon;
  const factory SpaceEvent.duplicate({
    FolderViewPB? space,
  }) = _Duplicate;
  const factory SpaceEvent.update({
    FolderViewPB? space,
    String? name,
    String? icon,
    String? iconColor,
    SpacePermission? permission,
  }) = _Update;
  const factory SpaceEvent.open(FolderViewPB space) = _Open;
  const factory SpaceEvent.expand(FolderViewPB space, bool isExpanded) =
      _Expand;
  const factory SpaceEvent.createPage({
    required String name,
    required ViewLayoutPB layout,
    int? index,
    required bool openAfterCreate,
  }) = _CreatePage;
  const factory SpaceEvent.delete(FolderViewPB? space) = _Delete;
  const factory SpaceEvent.didReceiveSpaceUpdate() = _DidReceiveSpaceUpdate;
  const factory SpaceEvent.reset(
    UserProfilePB userProfile,
    String workspaceId,
    bool openFirstPage,
  ) = _Reset;
  const factory SpaceEvent.migrate() = _Migrate;
  const factory SpaceEvent.switchToNextSpace() = _SwitchToNextSpace;
  const factory SpaceEvent.createSpace({
    required String name,
    required SpacePermission permission,
    required String icon,
    required String iconColor,
  }) = _CreateSpace;
  const factory SpaceEvent.switchCurrentSpace({
    required String spaceId,
  }) = _SwitchCurrentSpace;
}

@freezed
class SpaceState with _$SpaceState {
  const factory SpaceState({
    // use root view with space attributes to represent the space
    @Default([]) List<FolderViewPB> spaces,
    @Default(null) FolderViewPB? currentSpace,
    @Default(true) bool isExpanded,
    @Default(null) FolderViewPB? lastCreatedPage,
    FlowyResult<void, FlowyError>? createPageResult,
    @Default(false) bool shouldShowUpgradeDialog,
    @Default(false) bool isDuplicatingSpace,
    @Default(false) bool isInitialized,
  }) = _SpaceState;

  factory SpaceState.initial() => const SpaceState();
}
