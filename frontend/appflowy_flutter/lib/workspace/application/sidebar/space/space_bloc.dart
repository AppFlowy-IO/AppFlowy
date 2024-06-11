import 'dart:async';
import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_sections_listener.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
          initial: (userProfile, workspaceId) async {
            _initial(userProfile, workspaceId);

            final spaces = await _getSpaces();
            final currentSpace = await _getLastOpenedSpace(spaces);
            final isExpanded = await _getSpaceExpandStatus(currentSpace);
            emit(
              state.copyWith(
                spaces: spaces,
                currentSpace: currentSpace,
                isExpanded: isExpanded,
              ),
            );
          },
          create: (name, icon, permission) async {
            final space = await _createSpace(
              name: name,
              icon: icon,
              permission: permission,
            );
            if (space != null) {
              emit(state.copyWith(spaces: [...state.spaces, space]));
            }
          },
          rename: (space, name) async {
            final newSpace = await _rename(space, name);
            final spaces =
                state.spaces.map((e) => e.id == space.id ? newSpace : e);
            emit(state.copyWith(spaces: [...spaces]));
          },
          changeIcon: (icon) {},
          open: (space) async {
            await _openSpace(space);
            final isExpanded = await _getSpaceExpandStatus(space);
            emit(state.copyWith(currentSpace: space, isExpanded: isExpanded));
          },
        );
      },
    );
  }

  late WorkspaceService _workspaceService;
  WorkspaceSectionsListener? _listener;

  @override
  Future<void> close() async {
    await _listener?.stop();
    _listener = null;
    return super.close();
  }

  Future<List<ViewPB>> _getSpaces() async {
    final sectionViews = await _getSectionViews();
    if (sectionViews == null || sectionViews.views.isEmpty) {
      return [];
    }
    final publicViews = sectionViews.publicViews;
    final privateViews = sectionViews.privateViews;

    final publicSpaces = publicViews.where((e) => e.isSpace);
    final privateSpaces = privateViews.where((e) => e.isSpace);

    return [...publicSpaces, ...privateSpaces];
  }

  Future<ViewPB?> _createSpace({
    required String name,
    required String icon,
    required SpacePermission permission,
  }) async {
    final section = switch (permission) {
      SpacePermission.publicToAll => ViewSectionPB.Public,
      SpacePermission.private => ViewSectionPB.Private,
    };

    final result = await _workspaceService.createView(
      name: name,
      viewSection: section,
      setAsCurrent: false,
    );
    return result.fold((space) async {
      Log.info('Space created: $space');
      final extra = {
        ViewExtKeys.isSpaceKey: true,
        ViewExtKeys.spaceIconKey: icon,
        ViewExtKeys.spacePermissionKey: permission.index,
        ViewExtKeys.spaceCreatedAtKey: DateTime.now().millisecondsSinceEpoch,
      };
      await ViewBackendService.updateView(
        viewId: space.id,
        extra: jsonEncode(extra),
      );
      return space;
    }, (error) {
      Log.error('Failed to create space: $error');
      return null;
    });
  }

  Future<ViewPB> _rename(ViewPB view, String name) async {
    final result =
        await ViewBackendService.updateView(viewId: view.id, name: name);
    return result.fold((space) => space, (error) {
      Log.error('Failed to rename space: $error');
      return view;
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

    _listener = WorkspaceSectionsListener(
      user: userProfile,
      workspaceId: workspaceId,
    )..start(
        sectionChanged: (result) {},
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
      return null;
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
      return false;
    }

    return getIt<KeyValueStorage>().get(KVKeys.expandedViews).then((result) {
      if (result == null) {
        return true;
      }
      final map = jsonDecode(result);
      return map[space.id] ?? true;
    });
  }
}

@freezed
class SpaceEvent with _$SpaceEvent {
  const factory SpaceEvent.initial(
    UserProfilePB userProfile,
    String workspaceId,
  ) = _Initial;
  const factory SpaceEvent.create({
    required String name,
    required String icon,
    required SpacePermission permission,
  }) = _Create;
  const factory SpaceEvent.rename(ViewPB space, String name) = _Rename;
  const factory SpaceEvent.changeIcon(String icon) = _ChangeIcon;
  const factory SpaceEvent.open(ViewPB space) = _Open;
}

@freezed
class SpaceState with _$SpaceState {
  const factory SpaceState({
    // use root view with space attributes to represent the space
    @Default([]) List<ViewPB> spaces,
    @Default(null) ViewPB? currentSpace,
    @Default(true) bool isExpanded,
  }) = _SpaceState;

  factory SpaceState.initial() => const SpaceState();
}
