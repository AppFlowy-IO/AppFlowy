import 'dart:async';
import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/list_extension.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:appflowy/workspace/application/workspace/workspace_sections_listener.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:appflowy/workspace/presentation/settings/pages/fix_data_widget.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'space_bloc.freezed.dart';

enum SpacePermission {
  publicToAll,
  private,
}

class SidebarSection {
  const SidebarSection({
    required this.publicViews,
    required this.privateViews,
  });

  const SidebarSection.empty()
      : publicViews = const [],
        privateViews = const [];

  final List<ViewPB> publicViews;
  final List<ViewPB> privateViews;

  List<ViewPB> get views => publicViews + privateViews;

  SidebarSection copyWith({
    List<ViewPB>? publicViews,
    List<ViewPB>? privateViews,
  }) {
    return SidebarSection(
      publicViews: publicViews ?? this.publicViews,
      privateViews: privateViews ?? this.privateViews,
    );
  }
}

/// The [SpaceBloc] is responsible for
///   managing the root views in different sections of the workspace.
class SpaceBloc extends Bloc<SpaceEvent, SpaceState> {
  SpaceBloc() : super(SpaceState.initial()) {
    on<SpaceEvent>(
      (event, emit) async {
        await event.when(
          initial: (userProfile, workspaceId, openFirstPage) async {
            _initial(userProfile, workspaceId);

            final (spaces, publicViews, privateViews) = await _getSpaces();

            final shouldShowUpgradeDialog = await this.shouldShowUpgradeDialog(
              spaces: spaces,
              publicViews: publicViews,
              privateViews: privateViews,
            );

            final currentSpace = await _getLastOpenedSpace(spaces);
            final isExpanded = await _getSpaceExpandStatus(currentSpace);
            emit(
              state.copyWith(
                spaces: spaces,
                currentSpace: currentSpace,
                isExpanded: isExpanded,
                shouldShowUpgradeDialog: shouldShowUpgradeDialog,
                isInitialized: true,
                issueViews: [],
              ),
            );

            if (shouldShowUpgradeDialog && !integrationMode().isTest) {
              add(const SpaceEvent.migrate());
            }

            if (openFirstPage) {
              if (currentSpace != null) {
                add(SpaceEvent.open(currentSpace));
              }
            }

            if (!hasRunCheck) {
              unawaited(_checkViewsRelationship());
            }
          },
          create: (
            name,
            icon,
            iconColor,
            permission,
            createNewPageByDefault,
          ) async {
            final space = await _createSpace(
              name: name,
              icon: icon,
              iconColor: iconColor,
              permission: permission,
            );
            if (space != null) {
              emit(
                state.copyWith(
                  spaces: [...state.spaces, space],
                  currentSpace: space,
                ),
              );
              add(SpaceEvent.open(space));

              if (createNewPageByDefault) {
                add(
                  SpaceEvent.createPage(
                    name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
                    index: 0,
                    layout: ViewLayoutPB.Document,
                  ),
                );
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
            await ViewBackendService.delete(viewId: deletedSpace.id);
          },
          rename: (space, name) async {
            add(SpaceEvent.update(name: name));
          },
          changeIcon: (icon, iconColor) async {
            add(SpaceEvent.update(icon: icon, iconColor: iconColor));
          },
          update: (name, icon, iconColor, permission) async {
            final space = state.currentSpace;
            if (space == null) {
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
            if (PlatformExtension.isDesktop) {
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
                    lastCreatedPage: ViewPB(),
                  ),
                );
              }
            }
          },
          expand: (space, isExpanded) async {
            await _setSpaceExpandStatus(space, isExpanded);
            emit(state.copyWith(isExpanded: isExpanded));
          },
          createPage: (name, layout, index) async {
            final parentViewId = state.currentSpace?.id;
            if (parentViewId == null) {
              return;
            }

            final result = await ViewBackendService.createView(
              name: name,
              layoutType: layout,
              parentViewId: parentViewId,
              index: index,
            );
            result.fold(
              (view) {
                emit(
                  state.copyWith(
                    lastCreatedPage: view,
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
            final (spaces, _, _) = await _getSpaces();
            final currentSpace = await _getLastOpenedSpace(spaces);
            emit(
              state.copyWith(
                spaces: spaces,
                currentSpace: currentSpace,
              ),
            );
          },
          reset: (userProfile, workspaceId) async {
            if (workspaceId == _workspaceId) {
              return;
            }

            _reset(userProfile, workspaceId);

            add(
              SpaceEvent.initial(
                userProfile,
                workspaceId,
                openFirstPage: true,
              ),
            );
          },
          migrate: () async {
            final result = await migrate();
            emit(state.copyWith(shouldShowUpgradeDialog: !result));
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
          duplicate: () async {
            final currentSpace = state.currentSpace;
            if (currentSpace == null) {
              return;
            }
            emit(state.copyWith(isDuplicatingSpace: true));

            final newSpace = await _duplicateSpace(currentSpace);
            // open the duplicated space
            if (newSpace != null) {
              add(const SpaceEvent.didReceiveSpaceUpdate());
              add(SpaceEvent.open(newSpace));
            }

            emit(state.copyWith(isDuplicatingSpace: false));
          },
          reassignIssueViews: () async {
            await _reassignIssueViews();
          },
          updateIssueViews: (issueViews) async {
            emit(state.copyWith(issueViews: issueViews));
          },
        );
      },
    );
  }

  late WorkspaceService _workspaceService;
  String? _workspaceId;
  late UserProfilePB userProfile;
  WorkspaceSectionsListener? _listener;
  bool hasRunCheck = false;

  @override
  Future<void> close() async {
    await _listener?.stop();
    _listener = null;
    return super.close();
  }

  Future<(List<ViewPB>, List<ViewPB>, List<ViewPB>)> _getSpaces() async {
    final sectionViews = await _getSectionViews();
    if (sectionViews == null || sectionViews.views.isEmpty) {
      return (<ViewPB>[], <ViewPB>[], <ViewPB>[]);
    }

    final publicViews = sectionViews.publicViews.unique((e) => e.id);
    final privateViews = sectionViews.privateViews.unique((e) => e.id);

    final publicSpaces = publicViews.where((e) => e.isSpace);
    final privateSpaces = privateViews.where((e) => e.isSpace);

    return ([...publicSpaces, ...privateSpaces], publicViews, privateViews);
  }

  Future<ViewPB?> _createSpace({
    required String name,
    required String icon,
    required String iconColor,
    required SpacePermission permission,
    String? viewId,
  }) async {
    final section = switch (permission) {
      SpacePermission.publicToAll => ViewSectionPB.Public,
      SpacePermission.private => ViewSectionPB.Private,
    };

    final extra = {
      ViewExtKeys.isSpaceKey: true,
      ViewExtKeys.spaceIconKey: icon,
      ViewExtKeys.spaceIconColorKey: iconColor,
      ViewExtKeys.spacePermissionKey: permission.index,
      ViewExtKeys.spaceCreatedAtKey: DateTime.now().millisecondsSinceEpoch,
    };
    final result = await _workspaceService.createView(
      name: name,
      viewSection: section,
      setAsCurrent: true,
      viewId: viewId,
      extra: jsonEncode(extra),
    );
    return await result.fold((space) async {
      Log.info('Space created: $space');
      return space;
    }, (error) {
      Log.error('Failed to create space: $error');
      return null;
    });
  }

  Future<ViewPB> _rename(ViewPB space, String name) async {
    final result =
        await ViewBackendService.updateView(viewId: space.id, name: name);
    return result.fold((_) {
      space.freeze();
      return space.rebuild((b) => b.name = name);
    }, (error) {
      Log.error('Failed to rename space: $error');
      return space;
    });
  }

  Future<SidebarSection?> _getSectionViews() async {
    try {
      final publicViews = await _workspaceService.getPublicViews().getOrThrow();
      final privateViews =
          await _workspaceService.getPrivateViews().getOrThrow();
      return SidebarSection(
        publicViews: publicViews,
        privateViews: privateViews,
      );
    } catch (e) {
      Log.error('Failed to get section views: $e');
      return null;
    }
  }

  void _initial(UserProfilePB userProfile, String workspaceId) {
    _workspaceService = WorkspaceService(workspaceId: workspaceId);
    _workspaceId = workspaceId;
    this.userProfile = userProfile;

    hasRunCheck = false;

    _listener = WorkspaceSectionsListener(
      user: userProfile,
      workspaceId: workspaceId,
    )..start(
        sectionChanged: (result) async {
          add(const SpaceEvent.didReceiveSpaceUpdate());
        },
      );
  }

  void _reset(UserProfilePB userProfile, String workspaceId) {
    _listener?.stop();
    _listener = null;

    _initial(userProfile, workspaceId);
  }

  Future<ViewPB?> _getLastOpenedSpace(List<ViewPB> spaces) async {
    if (spaces.isEmpty) {
      return null;
    }

    final spaceId =
        await getIt<KeyValueStorage>().get(KVKeys.lastOpenedSpaceId);
    if (spaceId == null) {
      return spaces.first;
    }

    final space =
        spaces.firstWhereOrNull((e) => e.id == spaceId) ?? spaces.first;
    return space;
  }

  Future<void> _openSpace(ViewPB space) async {
    await getIt<KeyValueStorage>().set(KVKeys.lastOpenedSpaceId, space.id);
  }

  Future<void> _setSpaceExpandStatus(ViewPB? space, bool isExpanded) async {
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
      map[space.id] = true;
    } else {
      // remove the expand status if it's expanded
      map.remove(space.id);
    }
    await getIt<KeyValueStorage>().set(KVKeys.expandedViews, jsonEncode(map));
  }

  Future<bool> _getSpaceExpandStatus(ViewPB? space) async {
    if (space == null) {
      return true;
    }

    return getIt<KeyValueStorage>().get(KVKeys.expandedViews).then((result) {
      if (result == null) {
        return true;
      }
      final map = jsonDecode(result);
      return map[space.id] ?? true;
    });
  }

  Future<bool> migrate({bool auto = true}) async {
    if (_workspaceId == null) {
      return false;
    }

    try {
      final user =
          await UserBackendService.getCurrentUserProfile().getOrThrow();
      final service = UserBackendService(userId: user.id);
      final members =
          await service.getWorkspaceMembers(_workspaceId!).getOrThrow();
      final isOwner = members.items
          .any((e) => e.role == AFRolePB.Owner && e.email == user.email);

      if (members.items.isEmpty) {
        return true;
      }

      // only one member in the workspace, migrate it immediately
      // only the owner can migrate the public space
      if (members.items.length == 1 || isOwner) {
        // create a new public space and a new private space
        // move all the views in the workspace to the new public/private space
        var publicViews = await _workspaceService.getPublicViews().getOrThrow();
        final containsPublicSpace = publicViews.any(
          (e) => e.isSpace && e.spacePermission == SpacePermission.publicToAll,
        );
        publicViews = publicViews.where((e) => !e.isSpace).toList();

        for (final view in publicViews) {
          Log.info(
            'migrating: the public view should be migrated: ${view.name}(${view.id})',
          );
        }

        // if there is already a public space, don't migrate the public space
        // only migrate the public space if there are any public views
        if (publicViews.isEmpty || containsPublicSpace) {
          return true;
        }

        final viewId = fixedUuid(user.id.toInt(), UuidType.publicSpace);
        final publicSpace = await _createSpace(
          name: 'Shared',
          icon: builtInSpaceIcons.first,
          iconColor: builtInSpaceColors.first,
          permission: SpacePermission.publicToAll,
          viewId: viewId,
        );

        Log.info('migrating: created a new public space: ${publicSpace?.id}');

        if (publicSpace != null) {
          for (final view in publicViews.reversed) {
            if (view.isSpace) {
              continue;
            }
            await ViewBackendService.moveViewV2(
              viewId: view.id,
              newParentId: publicSpace.id,
              prevViewId: null,
            );
            Log.info(
              'migrating: migrate ${view.name}(${view.id}) to public space(${publicSpace.id})',
            );
          }
        }
      }

      // create a new private space
      final viewId = fixedUuid(user.id.toInt(), UuidType.privateSpace);
      var privateViews = await _workspaceService.getPrivateViews().getOrThrow();
      // if there is already a private space, don't migrate the private space
      final containsPrivateSpace = privateViews.any(
        (e) => e.isSpace && e.spacePermission == SpacePermission.private,
      );
      privateViews = privateViews.where((e) => !e.isSpace).toList();

      for (final view in privateViews) {
        Log.info(
          'migrating: the private view should be migrated: ${view.name}(${view.id})',
        );
      }

      if (privateViews.isEmpty || containsPrivateSpace) {
        return true;
      }
      // only migrate the private space if there are any private views
      final privateSpace = await _createSpace(
        name: 'Private',
        icon: builtInSpaceIcons.last,
        iconColor: builtInSpaceColors.last,
        permission: SpacePermission.private,
        viewId: viewId,
      );
      Log.info('migrating: created a new private space: ${privateSpace?.id}');

      if (privateSpace != null) {
        for (final view in privateViews.reversed) {
          if (view.isSpace) {
            continue;
          }
          await ViewBackendService.moveViewV2(
            viewId: view.id,
            newParentId: privateSpace.id,
            prevViewId: null,
          );
          Log.info(
            'migrating: migrate ${view.name}(${view.id}) to private space(${privateSpace.id})',
          );
        }
      }

      return true;
    } catch (e) {
      Log.error('migrate space error: $e');
      return false;
    }
  }

  Future<void> _checkViewsRelationship() async {
    // during moving, some views were assigned to the a parent view id,
    //  but they are not in the parent view's child views
    final issueViews = await WorkspaceDataManager.checkViewHealth();
    for (final view in issueViews) {
      Log.info('space: found an issue: $view is not in its parent view');
    }

    add(SpaceEvent.updateIssueViews(issueViews));
  }

  Future<bool> shouldShowUpgradeDialog({
    required List<ViewPB> spaces,
    required List<ViewPB> publicViews,
    required List<ViewPB> privateViews,
  }) async {
    final publicSpaces = spaces.where(
      (e) => e.spacePermission == SpacePermission.publicToAll,
    );
    if (publicSpaces.isEmpty && publicViews.isNotEmpty) {
      return true;
    }

    final privateSpaces = spaces.where(
      (e) => e.spacePermission == SpacePermission.private,
    );
    if (privateSpaces.isEmpty && privateViews.isNotEmpty) {
      return true;
    }

    return false;
  }

  Future<ViewPB?> _duplicateSpace(ViewPB space) async {
    // if the space is not duplicated, try to create a new space
    final icon = space.icon.value.isNotEmpty
        ? space.icon.value
        : builtInSpaceIcons.first;
    final iconColor = space.spaceIconColor ?? builtInSpaceColors.first;
    final newSpace = await _createSpace(
      name: '${space.name} (copy)',
      icon: icon,
      iconColor: iconColor,
      permission: space.spacePermission,
    );

    if (newSpace == null) {
      return null;
    }

    for (final view in space.childViews) {
      await ViewBackendService.duplicate(
        view: view,
        openAfterDuplicate: true,
        syncAfterDuplicate: true,
        includeChildren: true,
        parentViewId: newSpace.id,
        suffix: '',
      );
    }

    Log.info('Space duplicated: $newSpace');

    return newSpace;
  }

  Future<void> _reassignIssueViews() async {
    final issueViews = state.issueViews;
    if (issueViews.isEmpty) {
      return;
    }
    for (final view in issueViews) {
      final result = await ViewBackendService.moveViewV2(
        viewId: view.id,
        newParentId: view.parentViewId,
        prevViewId: null,
      );
      result.fold(
        (_) {
          Log.info('space: reassign issue view: ${view.name}(${view.id})');
        },
        (error) {
          Log.error('space: failed to reassign issue view: $error');
        },
      );
    }
  }
}

@freezed
class SpaceEvent with _$SpaceEvent {
  const factory SpaceEvent.initial(
    UserProfilePB userProfile,
    String workspaceId, {
    required bool openFirstPage,
  }) = _Initial;
  const factory SpaceEvent.create({
    required String name,
    required String icon,
    required String iconColor,
    required SpacePermission permission,
    required bool createNewPageByDefault,
  }) = _Create;
  const factory SpaceEvent.rename(ViewPB space, String name) = _Rename;
  const factory SpaceEvent.changeIcon(String icon, String iconColor) =
      _ChangeIcon;
  const factory SpaceEvent.duplicate() = _Duplicate;
  const factory SpaceEvent.update({
    String? name,
    String? icon,
    String? iconColor,
    SpacePermission? permission,
  }) = _Update;
  const factory SpaceEvent.open(ViewPB space) = _Open;
  const factory SpaceEvent.expand(ViewPB space, bool isExpanded) = _Expand;
  const factory SpaceEvent.createPage({
    required String name,
    required ViewLayoutPB layout,
    int? index,
  }) = _CreatePage;
  const factory SpaceEvent.delete(ViewPB? space) = _Delete;
  const factory SpaceEvent.didReceiveSpaceUpdate() = _DidReceiveSpaceUpdate;
  const factory SpaceEvent.reset(
    UserProfilePB userProfile,
    String workspaceId,
  ) = _Reset;
  const factory SpaceEvent.migrate() = _Migrate;
  const factory SpaceEvent.switchToNextSpace() = _SwitchToNextSpace;
  const factory SpaceEvent.reassignIssueViews() = _ReassignIssueViews;
  const factory SpaceEvent.updateIssueViews(List<ViewPB> issueViews) =
      _UpdateIssueViews;
}

@freezed
class SpaceState with _$SpaceState {
  const factory SpaceState({
    // use root view with space attributes to represent the space
    @Default([]) List<ViewPB> spaces,
    @Default(null) ViewPB? currentSpace,
    @Default(true) bool isExpanded,
    @Default(null) ViewPB? lastCreatedPage,
    FlowyResult<void, FlowyError>? createPageResult,
    @Default(false) bool shouldShowUpgradeDialog,
    @Default(false) bool isDuplicatingSpace,
    @Default(false) bool isInitialized,
    @Default([]) List<ViewPB> issueViews,
  }) = _SpaceState;

  factory SpaceState.initial() => const SpaceState();
}
