import 'dart:async';

import 'package:appflowy/features/workspace/data/repositories/workspace_repository.dart';
import 'package:appflowy/features/workspace/logic/workspace_event.dart';
import 'package:appflowy/features/workspace/logic/workspace_state.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:protobuf/protobuf.dart';

export 'workspace_event.dart';
export 'workspace_state.dart';

class _WorkspaceFetchResult {
  const _WorkspaceFetchResult({
    this.currentWorkspace,
    required this.workspaces,
    required this.shouldOpenWorkspace,
  });

  final UserWorkspacePB? currentWorkspace;
  final List<UserWorkspacePB> workspaces;
  final bool shouldOpenWorkspace;
}

class UserWorkspaceBloc extends Bloc<UserWorkspaceEvent, UserWorkspaceState> {
  UserWorkspaceBloc({
    required WorkspaceRepository repository,
    required UserProfilePB userProfile,
    this.initialWorkspaceId,
  })  : _repository = repository,
        _listener = UserListener(userProfile: userProfile),
        super(UserWorkspaceState.initial(userProfile)) {
    on<WorkspaceEventInitialize>(_onInitialize);
    on<WorkspaceEventFetchWorkspaces>(_onFetchWorkspaces);
    on<WorkspaceEventCreateWorkspace>(_onCreateWorkspace);
    on<WorkspaceEventDeleteWorkspace>(_onDeleteWorkspace);
    on<WorkspaceEventOpenWorkspace>(_onOpenWorkspace);
    on<WorkspaceEventRenameWorkspace>(_onRenameWorkspace);
    on<WorkspaceEventUpdateWorkspaceIcon>(_onUpdateWorkspaceIcon);
    on<WorkspaceEventLeaveWorkspace>(_onLeaveWorkspace);
    on<WorkspaceEventFetchWorkspaceSubscriptionInfo>(
      _onFetchWorkspaceSubscriptionInfo,
    );
  }

  final WorkspaceRepository _repository;
  final UserListener _listener;
  final String? initialWorkspaceId;

  @override
  Future<void> close() {
    _listener.stop();
    return super.close();
  }

  Future<void> _onInitialize(
    WorkspaceEventInitialize event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    _setupListeners(emit);
    await _initializeWorkspaces(emit);
  }

  Future<void> _onFetchWorkspaces(
    WorkspaceEventFetchWorkspaces event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _handleFetchWorkspaces(emit, event.initialWorkspaceId);
  }

  Future<void> _onCreateWorkspace(
    WorkspaceEventCreateWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _handleCreateWorkspace(emit, event.name, event.workspaceType);
  }

  Future<void> _onDeleteWorkspace(
    WorkspaceEventDeleteWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _handleDeleteWorkspace(emit, event.workspaceId);
  }

  Future<void> _onOpenWorkspace(
    WorkspaceEventOpenWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _handleOpenWorkspace(emit, event.workspaceId, event.workspaceType);
  }

  Future<void> _onRenameWorkspace(
    WorkspaceEventRenameWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _handleRenameWorkspace(emit, event.workspaceId, event.name);
  }

  Future<void> _onUpdateWorkspaceIcon(
    WorkspaceEventUpdateWorkspaceIcon event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _handleUpdateWorkspaceIcon(emit, event.workspaceId, event.icon);
  }

  Future<void> _onLeaveWorkspace(
    WorkspaceEventLeaveWorkspace event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _handleLeaveWorkspace(emit, event.workspaceId);
  }

  Future<void> _onFetchWorkspaceSubscriptionInfo(
    WorkspaceEventFetchWorkspaceSubscriptionInfo event,
    Emitter<UserWorkspaceState> emit,
  ) async {
    await _handleFetchWorkspaceSubscriptionInfo(emit, event.workspaceId);
  }

  void _setupListeners(Emitter<UserWorkspaceState> emit) {
    _listener.start(
      onProfileUpdated: (result) {
        if (!isClosed) {
          result.fold(
            (newProfile) => emit(
              state.copyWith(userProfile: newProfile),
            ),
            (error) => Log.error("Failed to get user profile: $error"),
          );
        }
      },
      onUserWorkspaceListUpdated: (workspaces) {
        if (!isClosed) {
          emit(
            state.copyWith(
              workspaces: _sortWorkspaces(workspaces.items),
            ),
          );
        }
      },
      onUserWorkspaceUpdated: (workspace) {
        if (!isClosed) {
          final currentWorkspace = state.currentWorkspace;
          if (currentWorkspace?.workspaceId == workspace.workspaceId) {
            emit(
              state.copyWith(currentWorkspace: workspace),
            );
          }
        }
      },
    );
  }

  Future<void> _handleFetchWorkspaceSubscriptionInfo(
    Emitter<UserWorkspaceState> emit,
    String workspaceId,
  ) async {
    final enabled = await isBillingEnabled();
    // If billing is not enabled, we don't need to fetch the workspace subscription info
    if (!enabled) {
      return;
    }

    unawaited(
      _repository
          .getWorkspaceSubscriptionInfo(
        workspaceId: workspaceId,
      )
          .fold(
        (workspaceSubscriptionInfo) {
          if (isClosed) {
            return;
          }

          if (state.currentWorkspace?.workspaceId != workspaceId) {
            return;
          }

          Log.debug(
            'fetch workspace subscription info: $workspaceId, $workspaceSubscriptionInfo',
          );

          emit(
            state.copyWith(
              workspaceSubscriptionInfo: workspaceSubscriptionInfo,
            ),
          );
        },
        (e) => Log.error('fetch workspace subscription info error: $e'),
      ),
    );
  }

  Future<void> _initializeWorkspaces(Emitter<UserWorkspaceState> emit) async {
    final result = await _fetchWorkspaces(
      initialWorkspaceId: initialWorkspaceId,
    );
    final currentWorkspace = result.currentWorkspace;
    final workspaces = result.workspaces;
    final isCollabWorkspaceOn =
        state.userProfile.userAuthType == AuthTypePB.Server &&
            FeatureFlag.collaborativeWorkspace.isOn;

    Log.info(
      'init workspace, current workspace: ${currentWorkspace?.workspaceId}, '
      'workspaces: ${workspaces.map((e) => e.workspaceId)}, isCollabWorkspaceOn: $isCollabWorkspaceOn',
    );

    if (currentWorkspace != null) {
      add(
        UserWorkspaceEvent.fetchWorkspaceSubscriptionInfo(
          workspaceId: currentWorkspace.workspaceId,
        ),
      );
    }

    if (currentWorkspace != null && result.shouldOpenWorkspace == true) {
      Log.info('init open workspace: ${currentWorkspace.workspaceId}');
      await _repository.openWorkspace(
        workspaceId: currentWorkspace.workspaceId,
        workspaceType: currentWorkspace.workspaceType,
      );
    }

    emit(
      state.copyWith(
        currentWorkspace: currentWorkspace,
        workspaces: workspaces,
        isCollabWorkspaceOn: isCollabWorkspaceOn,
        actionResult: const WorkspaceActionResult(
          actionType: WorkspaceActionType.none,
          isLoading: false,
          result: null,
        ),
      ),
    );
  }

  Future<void> _handleFetchWorkspaces(
    Emitter<UserWorkspaceState> emit,
    String? initialWorkspaceId,
  ) async {
    final result = await _fetchWorkspaces(
      initialWorkspaceId: initialWorkspaceId,
    );

    final currentWorkspace = result.currentWorkspace;
    final workspaces = result.workspaces;
    Log.info(
      'fetch workspaces: current workspace: ${currentWorkspace?.workspaceId}, workspaces: ${workspaces.map((e) => e.workspaceId)}',
    );

    emit(
      state.copyWith(
        workspaces: workspaces,
      ),
    );

    if (currentWorkspace != null &&
        currentWorkspace.workspaceId != state.currentWorkspace?.workspaceId) {
      Log.info(
        'fetch workspaces: try to open workspace: ${currentWorkspace.workspaceId}',
      );
      add(
        UserWorkspaceEvent.openWorkspace(
          workspaceId: currentWorkspace.workspaceId,
          workspaceType: currentWorkspace.workspaceType,
        ),
      );
    }
  }

  Future<void> _handleCreateWorkspace(
    Emitter<UserWorkspaceState> emit,
    String name,
    WorkspaceTypePB workspaceType,
  ) async {
    emit(
      state.copyWith(
        actionResult: const WorkspaceActionResult(
          actionType: WorkspaceActionType.create,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final result = await _repository.createWorkspace(
      name: name,
      workspaceType: workspaceType,
    );

    final workspaces = result.fold(
      (s) => [...state.workspaces, s],
      (e) => state.workspaces,
    );

    emit(
      state.copyWith(
        workspaces: _sortWorkspaces(workspaces),
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.create,
          isLoading: false,
          result: result.map((_) {}),
        ),
      ),
    );

    result
      ..onSuccess((s) {
        Log.info('create workspace success: $s');
        add(
          UserWorkspaceEvent.openWorkspace(
            workspaceId: s.workspaceId,
            workspaceType: s.workspaceType,
          ),
        );
      })
      ..onFailure((f) {
        Log.error('create workspace error: $f');
      });
  }

  Future<void> _handleDeleteWorkspace(
    Emitter<UserWorkspaceState> emit,
    String workspaceId,
  ) async {
    Log.info('try to delete workspace: $workspaceId');
    emit(
      state.copyWith(
        actionResult: const WorkspaceActionResult(
          actionType: WorkspaceActionType.delete,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final remoteWorkspaces = await _fetchWorkspaces().then(
      (value) => value.workspaces,
    );

    if (state.workspaces.length <= 1 || remoteWorkspaces.length <= 1) {
      final result = FlowyResult.failure(
        FlowyError(
          code: ErrorCode.Internal,
          msg: LocaleKeys.workspace_cannotDeleteTheOnlyWorkspace.tr(),
        ),
      );
      return emit(
        state.copyWith(
          actionResult: WorkspaceActionResult(
            actionType: WorkspaceActionType.delete,
            result: result,
            isLoading: false,
          ),
        ),
      );
    }

    final result = await _repository.deleteWorkspace(
      workspaceId: workspaceId,
    );
    final workspacesResult = await _fetchWorkspaces();
    final workspaces = workspacesResult.workspaces;
    final containsDeletedWorkspace =
        _findWorkspaceById(workspaceId, workspaces) != null;

    result
      ..onSuccess((_) {
        Log.info('delete workspace success: $workspaceId');
        final firstWorkspace = workspaces.firstOrNull;
        assert(
          firstWorkspace != null,
          'the first workspace must not be null',
        );
        if (state.currentWorkspace?.workspaceId == workspaceId &&
            firstWorkspace != null) {
          Log.info(
            'delete workspace: open the first workspace: ${firstWorkspace.workspaceId}',
          );
          add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: firstWorkspace.workspaceId,
              workspaceType: firstWorkspace.workspaceType,
            ),
          );
        }
      })
      ..onFailure((f) {
        Log.error('delete workspace error: $f');
        if (!containsDeletedWorkspace && workspaces.isNotEmpty) {
          add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: workspaces.first.workspaceId,
              workspaceType: workspaces.first.workspaceType,
            ),
          );
        }
      });

    emit(
      state.copyWith(
        workspaces: workspaces,
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.delete,
          result: result,
          isLoading: false,
        ),
      ),
    );
  }

  Future<void> _handleOpenWorkspace(
    Emitter<UserWorkspaceState> emit,
    String workspaceId,
    WorkspaceTypePB workspaceType,
  ) async {
    emit(
      state.copyWith(
        actionResult: const WorkspaceActionResult(
          actionType: WorkspaceActionType.open,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final result = await _repository.openWorkspace(
      workspaceId: workspaceId,
      workspaceType: workspaceType,
    );

    final currentWorkspace = result.fold(
      (s) => _findWorkspaceById(workspaceId),
      (e) => state.currentWorkspace,
    );

    result
      ..onSuccess((s) {
        add(
          UserWorkspaceEvent.fetchWorkspaceSubscriptionInfo(
            workspaceId: workspaceId,
          ),
        );

        Log.info(
          'open workspace success: $workspaceId, current workspace: ${currentWorkspace?.toProto3Json()}',
        );
      })
      ..onFailure((f) {
        Log.error('open workspace error: $f');
      });

    emit(
      state.copyWith(
        currentWorkspace: currentWorkspace,
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.open,
          isLoading: false,
          result: result,
        ),
      ),
    );

    getIt<ReminderBloc>().add(
      ReminderEvent.started(),
    );
  }

  Future<void> _handleRenameWorkspace(
    Emitter<UserWorkspaceState> emit,
    String workspaceId,
    String name,
  ) async {
    final result = await _repository.renameWorkspace(
      workspaceId: workspaceId,
      name: name,
    );

    final workspaces = result.fold(
      (s) => _updateWorkspaceInList(workspaceId, (workspace) {
        workspace.freeze();
        return workspace.rebuild((p0) {
          p0.name = name;
        });
      }),
      (f) => state.workspaces,
    );

    final currentWorkspace = _findWorkspaceById(
      state.currentWorkspace?.workspaceId ?? '',
      workspaces,
    );

    Log.info('rename workspace: $workspaceId, name: $name');

    result.onFailure((f) {
      Log.error('rename workspace error: $f');
    });

    emit(
      state.copyWith(
        workspaces: workspaces,
        currentWorkspace: currentWorkspace,
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.rename,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _handleUpdateWorkspaceIcon(
    Emitter<UserWorkspaceState> emit,
    String workspaceId,
    String icon,
  ) async {
    final workspace = _findWorkspaceById(workspaceId);
    if (workspace == null) {
      Log.error('workspace not found: $workspaceId');
      return;
    }

    if (icon == workspace.icon) {
      Log.info('ignore same icon update');
      return;
    }

    final result = await _repository.updateWorkspaceIcon(
      workspaceId: workspaceId,
      icon: icon,
    );

    final workspaces = result.fold(
      (s) => _updateWorkspaceInList(workspaceId, (workspace) {
        workspace.freeze();
        return workspace.rebuild((p0) {
          p0.icon = icon;
        });
      }),
      (f) => state.workspaces,
    );

    final currentWorkspace = _findWorkspaceById(
      state.currentWorkspace?.workspaceId ?? '',
      workspaces,
    );

    Log.info('update workspace icon: $workspaceId, icon: $icon');

    result.onFailure((f) {
      Log.error('update workspace icon error: $f');
    });

    emit(
      state.copyWith(
        workspaces: workspaces,
        currentWorkspace: currentWorkspace,
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.updateIcon,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _handleLeaveWorkspace(
    Emitter<UserWorkspaceState> emit,
    String workspaceId,
  ) async {
    final result = await _repository.leaveWorkspace(
      workspaceId: workspaceId,
    );

    final workspaces = result.fold(
      (s) =>
          state.workspaces.where((e) => e.workspaceId != workspaceId).toList(),
      (e) => state.workspaces,
    );

    result
      ..onSuccess((_) {
        Log.info('leave workspace success: $workspaceId');
        if (state.currentWorkspace?.workspaceId == workspaceId &&
            workspaces.isNotEmpty) {
          add(
            UserWorkspaceEvent.openWorkspace(
              workspaceId: workspaces.first.workspaceId,
              workspaceType: workspaces.first.workspaceType,
            ),
          );
        }
      })
      ..onFailure((f) {
        Log.error('leave workspace error: $f');
      });

    emit(
      state.copyWith(
        workspaces: _sortWorkspaces(workspaces),
        actionResult: WorkspaceActionResult(
          actionType: WorkspaceActionType.leave,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  // Helper methods
  List<UserWorkspacePB> _sortWorkspaces(List<UserWorkspacePB> workspaces) {
    final sorted = [...workspaces];
    sorted.sort(
      (a, b) => a.createdAtTimestamp.compareTo(b.createdAtTimestamp),
    );
    return sorted;
  }

  UserWorkspacePB? _findWorkspaceById(
    String id, [
    List<UserWorkspacePB>? workspacesList,
  ]) {
    final workspaces = workspacesList ?? state.workspaces;
    return workspaces.firstWhereOrNull((e) => e.workspaceId == id);
  }

  List<UserWorkspacePB> _updateWorkspaceInList(
    String workspaceId,
    UserWorkspacePB Function(UserWorkspacePB workspace) updater,
  ) {
    final workspaces = [...state.workspaces];
    final index = workspaces.indexWhere((e) => e.workspaceId == workspaceId);
    if (index != -1) {
      workspaces[index] = updater(workspaces[index]);
    }
    return workspaces;
  }

  Future<_WorkspaceFetchResult> _fetchWorkspaces({
    String? initialWorkspaceId,
  }) async {
    try {
      final currentWorkspaceResult = await _repository.getCurrentWorkspace();
      final currentWorkspace = currentWorkspaceResult.fold(
        (s) => s,
        (e) => null,
      );
      final currentWorkspaceId = initialWorkspaceId ?? currentWorkspace?.id;
      final workspacesResult = await _repository.getWorkspaces();
      final workspaces = workspacesResult.getOrThrow();

      if (workspaces.isEmpty && currentWorkspace != null) {
        workspaces.add(
          _convertWorkspacePBToUserWorkspace(currentWorkspace),
        );
      }

      final currentWorkspaceInList = _findWorkspaceById(
            currentWorkspaceId ?? '',
            workspaces,
          ) ??
          workspaces.firstOrNull;

      final sortedWorkspaces = _sortWorkspaces(workspaces);

      Log.info(
        'fetch workspaces: current workspace: ${currentWorkspaceInList?.workspaceId}, sorted workspaces: ${sortedWorkspaces.map((e) => '${e.name}: ${e.workspaceId}')}',
      );

      return _WorkspaceFetchResult(
        currentWorkspace: currentWorkspaceInList,
        workspaces: sortedWorkspaces,
        shouldOpenWorkspace:
            currentWorkspaceInList?.workspaceId != currentWorkspaceId,
      );
    } catch (e) {
      Log.error('fetch workspace error: $e');
      return _WorkspaceFetchResult(
        currentWorkspace: state.currentWorkspace,
        workspaces: state.workspaces,
        shouldOpenWorkspace: false,
      );
    }
  }

  UserWorkspacePB _convertWorkspacePBToUserWorkspace(WorkspacePB workspace) {
    return UserWorkspacePB.create()
      ..workspaceId = workspace.id
      ..name = workspace.name
      ..createdAtTimestamp = workspace.createTime;
  }
}
