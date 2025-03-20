import 'dart:async';
import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:appflowy/workspace/application/workspace/workspace_sections_listener.dart';
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
///   managing the root views in different sections of the workspace.
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
            final space = await _createSpace(
              name: name,
              icon: icon,
              iconColor: iconColor,
              permission: permission,
            );

            Log.info('create space: $space');

            if (space != null) {
              emit(
                state.copyWith(
                  spaces: [...state.spaces, space],
                  currentSpace: space,
                ),
              );
              add(SpaceEvent.open(space));
              Log.info('open space: ${space.name}(${space.id})');

              if (createNewPageByDefault) {
                add(
                  SpaceEvent.createPage(
                    name: '',
                    index: 0,
                    layout: ViewLayoutPB.Document,
                    openAfterCreate: openAfterCreate,
                  ),
                );
                Log.info('create page: ${space.name}(${space.id})');
              }
            }
          },
          delete: (space) async {
            if (state.spaces.length <= 1) {
              return;
            }

            final deletedSpace = space ?? state.currentSpace;
            if (deletedSpace == null) {
              return;
            }

            await ViewBackendService.deleteView(viewId: deletedSpace.id);

            Log.info('delete space: ${deletedSpace.name}(${deletedSpace.id})');
          },
          rename: (space, name) async {
            add(
              SpaceEvent.update(
                space: space,
                name: name,
                icon: space.spaceIcon,
                iconColor: space.spaceIconColor,
                permission: space.spacePermission,
              ),
            );
          },
          changeIcon: (space, icon, iconColor) async {
            add(
              SpaceEvent.update(
                space: space,
                icon: icon,
                iconColor: iconColor,
              ),
            );
          },
          update: (space, name, icon, iconColor, permission) async {
            space ??= state.currentSpace;
            if (space == null) {
              Log.error('update space failed, space is null');
              return;
            }

            if (name != null) {
              await _rename(space, name);
            }

            if (icon != null || iconColor != null || permission != null) {
              try {
                final extra = space.extra;
                final current = extra.isNotEmpty == true
                    ? jsonDecode(extra)
                    : <String, dynamic>{};
                final updated = <String, dynamic>{};
                if (icon != null) {
                  updated[ViewExtKeys.spaceIconKey] = icon;
                }
                if (iconColor != null) {
                  updated[ViewExtKeys.spaceIconColorKey] = iconColor;
                }
                if (permission != null) {
                  updated[ViewExtKeys.spacePermissionKey] = permission.index;
                }
                final merged = mergeMaps(current, updated);
                await ViewBackendService.updateView(
                  viewId: space.id,
                  extra: jsonEncode(merged),
                );

                Log.info(
                  'update space: ${space.name}(${space.id}), merged: $merged',
                );
              } catch (e) {
                Log.error('Failed to migrating cover: $e');
              }
            } else if (icon == null) {
              try {
                final extra = space.extra;
                final Map<String, dynamic> current = extra.isNotEmpty == true
                    ? jsonDecode(extra)
                    : <String, dynamic>{};
                current.remove(ViewExtKeys.spaceIconKey);
                current.remove(ViewExtKeys.spaceIconColorKey);
                await ViewBackendService.updateView(
                  viewId: space.id,
                  extra: jsonEncode(current),
                );

                Log.info(
                  'update space: ${space.name}(${space.id}), current: $current',
                );
              } catch (e) {
                Log.error('Failed to migrating cover: $e');
              }
            }

            if (permission != null) {
              await ViewBackendService.updateViewsVisibility(
                [space],
                permission == SpacePermission.publicToAll,
              );
            }
          },
          open: (space) async {
            await _openSpace(space);
            final isExpanded = await _getSpaceExpandStatus(space);
            final views = await ViewBackendService.getChildViews(
              viewId: space.id,
            );
            final currentSpace = views.fold(
              (views) {
                space.freeze();
                return space.rebuild((b) {
                  b.childViews.clear();
                  b.childViews.addAll(views);
                });
              },
              (_) => space,
            );
            emit(
              state.copyWith(
                currentSpace: currentSpace,
                isExpanded: isExpanded,
              ),
            );

            // don't open the page automatically on mobile
            if (UniversalPlatform.isDesktop) {
              // open the first page by default
              if (currentSpace.childViews.isNotEmpty) {
                final firstPage = currentSpace.childViews.first;
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
            final parentViewId = state.currentSpace?.id;
            if (parentViewId == null) {
              return;
            }

            final result = await ViewBackendService.createView(
              name: name,
              layoutType: layout,
              parentViewId: parentViewId,
              index: index,
              openAfterCreate: openAfterCreate,
            );
            result.fold(
              (view) {
                emit(
                  state.copyWith(
                    lastCreatedPage: openAfterCreate ? view : null,
                    createPageResult: FlowyResult.success(null),
                  ),
                );
              },
              (error) {
                Log.error('Failed to create root view: $error');
                emit(
                  state.copyWith(
                    createPageResult: FlowyResult.failure(error),
                  ),
                );
              },
            );
          },
          didReceiveSpaceUpdate: () async {
            // deprecated
            // do nothing
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

            Log.info('duplicate space: ${space.name}(${space.id})');

            emit(state.copyWith(isDuplicatingSpace: true));

            final newSpace = await _duplicateSpace(space);
            // open the duplicated space
            if (newSpace != null) {
              add(const SpaceEvent.didReceiveSpaceUpdate());
              add(SpaceEvent.open(newSpace));
            }

            emit(state.copyWith(isDuplicatingSpace: false));
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
    await _listener?.stop();
    _listener = null;
    return super.close();
  }

  Future<List<FolderViewPB>> _getSpaces() async {
    final response = await _workspaceService.getSpaces();
    final List<FolderViewPB> spaces = response.fold(
      (children) {
        return children;
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
      permission: permission.toSpacePermissionPB(),
    );
    return response.fold((_) {
      Log.info('Created space: $name, icon: $icon, iconColor: $iconColor');
    }, (error) {
      Log.error('Failed to create space: $error');
    });
  }

  Future<FolderViewPB> _rename(FolderViewPB space, String name) async {
    final response = await _workspaceService.updateSpaceName(
      spaceId: space.viewId,
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
  }

  void _reset(UserProfilePB userProfile, String workspaceId) {
    this.userProfile = userProfile;
    this.workspaceId = workspaceId;
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

  Future<FolderViewPB?> _duplicateSpace(FolderViewPB space) async {
    // fixme: duplicate space
    return null;
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
