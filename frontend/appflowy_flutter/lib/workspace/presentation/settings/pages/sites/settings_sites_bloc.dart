import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_sites_bloc.freezed.dart';

String _lastNamespace = '';

class SettingsSitesBloc extends Bloc<SettingsSitesEvent, SettingsSitesState> {
  SettingsSitesBloc({
    required this.workspaceId,
    required this.user,
  }) : super(const SettingsSitesState()) {
    on<SettingsSitesEvent>((event, emit) async {
      await event.when(
        initial: () async => _initial(emit),
        unpublishView: (viewId) async => _unpublishView(
          viewId,
          emit,
        ),
        updateNamespace: (namespace) async => _updateNamespace(
          namespace,
          emit,
        ),
        updatePublishName: (name) async => _updatePublishName(
          name,
          emit,
        ),
        upgradeSubscription: () async => _upgradeSubscription(emit),
      );
    });
  }

  final String workspaceId;
  final UserProfilePB user;

  Future<void> _initial(Emitter<SettingsSitesState> emit) async {
    emit(
      state.copyWith(
        isLoading: true,
        namespace: _lastNamespace,
      ),
    );

    // Combine fetching subscription info and namespace
    final (subscriptionInfo, namespace) = await (
      _fetchUserSubscription(),
      _fetchPublishNamespace(),
    ).wait;

    emit(
      state.copyWith(
        subscriptionInfo: subscriptionInfo,
        namespace: namespace,
      ),
    );

    // This request is not blocking, render the namespace and subscription info first.
    final publishViews = await _fetchPublishedViews();
    emit(
      state.copyWith(
        publishedViews: publishViews,
        isLoading: false,
      ),
    );
  }

  Future<WorkspaceSubscriptionInfoPB?> _fetchUserSubscription() async {
    final result = await UserBackendService.getWorkspaceSubscriptionInfo(
      workspaceId,
    );
    return result.fold((s) => s, (_) => null);
  }

  Future<String> _fetchPublishNamespace() async {
    final result = await FolderEventGetPublishNamespace().send();
    _lastNamespace = result.fold((s) => s.namespace, (_) => _lastNamespace);
    return _lastNamespace;
  }

  Future<List<PublishInfoViewPB>> _fetchPublishedViews() async {
    final result = await FolderEventListPublishedViews().send();
    return result.fold((s) => s.items, (_) => []);
  }

  Future<void> _unpublishView(
    String viewId,
    Emitter<SettingsSitesState> emit,
  ) async {
    emit(
      state.copyWith(
        actionResult: const SettingsSitesActionResult(
          actionType: SettingsSitesActionType.unpublishView,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final request = UnpublishViewsPayloadPB(viewIds: [viewId]);
    final result = await FolderEventUnpublishViews(request).send();
    final publishedViews = result.fold(
      (_) => state.publishedViews
          .where((view) => view.info.viewId != viewId)
          .toList(),
      (_) => state.publishedViews,
    );

    emit(
      state.copyWith(
        publishedViews: publishedViews,
        actionResult: SettingsSitesActionResult(
          actionType: SettingsSitesActionType.unpublishView,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _updateNamespace(
    String namespace,
    Emitter<SettingsSitesState> emit,
  ) async {
    emit(
      state.copyWith(
        actionResult: const SettingsSitesActionResult(
          actionType: SettingsSitesActionType.updateNamespace,
          isLoading: true,
          result: null,
        ),
      ),
    );

    final request = SetPublishNamespacePayloadPB()..newNamespace = namespace;
    final result = await FolderEventSetPublishNamespace(request).send();

    emit(
      state.copyWith(
        namespace: result.fold((_) => namespace, (_) => state.namespace),
        actionResult: SettingsSitesActionResult(
          actionType: SettingsSitesActionType.updateNamespace,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }

  Future<void> _updatePublishName(
    String name,
    Emitter<SettingsSitesState> emit,
  ) async {
    emit(
      state.copyWith(
        actionResult: const SettingsSitesActionResult(
          actionType: SettingsSitesActionType.updatePublishName,
          isLoading: true,
          result: null,
        ),
      ),
    );

    // todo: not implemented.
  }

  Future<void> _upgradeSubscription(Emitter<SettingsSitesState> emit) async {
    final userService = UserBackendService(userId: user.id);
    final result = await userService.createSubscription(
      workspaceId,
      SubscriptionPlanPB.Pro,
    );

    result.onSuccess((s) {
      afLaunchUrlString(s.paymentLink);
    });

    emit(
      state.copyWith(
        actionResult: SettingsSitesActionResult(
          actionType: SettingsSitesActionType.upgradeSubscription,
          isLoading: false,
          result: result,
        ),
      ),
    );
  }
}

@freezed
class SettingsSitesState with _$SettingsSitesState {
  const factory SettingsSitesState({
    @Default([]) List<PublishInfoViewPB> publishedViews,
    SettingsSitesActionResult? actionResult,
    @Default('') String namespace,
    @Default(null) WorkspaceSubscriptionInfoPB? subscriptionInfo,
    @Default(true) bool isLoading,
  }) = _SettingsSitesState;

  factory SettingsSitesState.initial() => const SettingsSitesState();
}

@freezed
class SettingsSitesEvent with _$SettingsSitesEvent {
  const factory SettingsSitesEvent.initial() = _Initial;
  const factory SettingsSitesEvent.unpublishView(String viewId) =
      _UnpublishView;
  const factory SettingsSitesEvent.updateNamespace(String namespace) =
      _UpdateNamespace;
  const factory SettingsSitesEvent.updatePublishName(String name) =
      _UpdatePublishName;
  const factory SettingsSitesEvent.upgradeSubscription() = _UpgradeSubscription;
}

enum SettingsSitesActionType {
  none,
  unpublishView,
  updateNamespace,
  fetchPublishedViews,
  updatePublishName,
  fetchUserSubscription,
  upgradeSubscription,
}

class SettingsSitesActionResult {
  const SettingsSitesActionResult({
    required this.actionType,
    required this.isLoading,
    required this.result,
  });

  factory SettingsSitesActionResult.none() => const SettingsSitesActionResult(
        actionType: SettingsSitesActionType.none,
        isLoading: false,
        result: null,
      );

  final SettingsSitesActionType actionType;
  final FlowyResult<void, FlowyError>? result;
  final bool isLoading;

  @override
  String toString() {
    return 'SettingsSitesActionResult(actionType: $actionType, isLoading: $isLoading, result: $result)';
  }
}
