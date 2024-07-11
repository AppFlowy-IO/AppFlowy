import 'package:flutter/foundation.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/subscription_success_listenable/subscription_success_listenable.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbserver.dart';
import 'package:bloc/bloc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_plan_bloc.freezed.dart';

class SettingsPlanBloc extends Bloc<SettingsPlanEvent, SettingsPlanState> {
  SettingsPlanBloc({
    required this.workspaceId,
    required Int64 userId,
  }) : super(const _Initial()) {
    _service = WorkspaceService(workspaceId: workspaceId);
    _userService = UserBackendService(userId: userId);
    _successListenable = getIt<SubscriptionSuccessListenable>();
    _successListenable.addListener(_onPaymentSuccessful);

    on<SettingsPlanEvent>((event, emit) async {
      await event.when(
        started: (withSuccessfulUpgrade, shouldLoad) async {
          if (shouldLoad) {
            emit(const SettingsPlanState.loading());
          }

          final snapshots = await Future.wait([
            _service.getWorkspaceUsage(),
            UserBackendService.getWorkspaceSubscriptionInfo(workspaceId),
          ]);

          FlowyError? error;

          final usageResult = snapshots.first.fold(
            (s) => s as WorkspaceUsagePB,
            (f) {
              error = f;
              return null;
            },
          );

          final subscriptionInfo = snapshots[1].fold(
            (s) => s as WorkspaceSubscriptionInfoPB,
            (f) {
              error = f;
              return null;
            },
          );

          if (usageResult == null ||
              subscriptionInfo == null ||
              error != null) {
            return emit(SettingsPlanState.error(error: error));
          }

          emit(
            SettingsPlanState.ready(
              workspaceUsage: usageResult,
              subscriptionInfo: subscriptionInfo,
              successfulPlanUpgrade: withSuccessfulUpgrade,
            ),
          );

          if (withSuccessfulUpgrade != null) {
            emit(
              SettingsPlanState.ready(
                workspaceUsage: usageResult,
                subscriptionInfo: subscriptionInfo,
              ),
            );
          }
        },
        addSubscription: (plan) async {
          final result = await _userService.createSubscription(
            workspaceId,
            plan,
          );

          result.fold(
            (pl) => afLaunchUrlString(pl.paymentLink),
            (f) => Log.error(f.msg, f),
          );
        },
        cancelSubscription: () async {
          final newState = state
              .mapOrNull(ready: (state) => state)
              ?.copyWith(downgradeProcessing: true);
          emit(newState ?? state);

          // We can hardcode the subscription plan here because we cannot cancel addons
          // on the Plan page
          await _userService.cancelSubscription(
            workspaceId,
            SubscriptionPlanPB.Pro,
          );

          add(const SettingsPlanEvent.started());
        },
        paymentSuccessful: (plan) {
          final readyState = state.mapOrNull(ready: (state) => state);
          if (readyState == null) {
            return;
          }

          add(
            SettingsPlanEvent.started(
              withSuccessfulUpgrade: plan,
              shouldLoad: false,
            ),
          );
        },
      );
    });
  }

  late final String workspaceId;
  late final WorkspaceService _service;
  late final IUserBackendService _userService;
  late final SubscriptionSuccessListenable _successListenable;

  Future<void> _onPaymentSuccessful() async {
    // Invalidate cache for this workspace
    await UserBackendService.invalidateWorkspaceSubscriptionCache(workspaceId);

    add(
      SettingsPlanEvent.paymentSuccessful(
        plan: _successListenable.subscribedPlan,
      ),
    );
  }

  @override
  Future<void> close() async {
    _successListenable.removeListener(_onPaymentSuccessful);
    return super.close();
  }
}

@freezed
class SettingsPlanEvent with _$SettingsPlanEvent {
  const factory SettingsPlanEvent.started({
    @Default(null) SubscriptionPlanPB? withSuccessfulUpgrade,
    @Default(true) bool shouldLoad,
  }) = _Started;

  const factory SettingsPlanEvent.addSubscription(SubscriptionPlanPB plan) =
      _AddSubscription;

  const factory SettingsPlanEvent.cancelSubscription() = _CancelSubscription;

  const factory SettingsPlanEvent.paymentSuccessful({
    @Default(null) SubscriptionPlanPB? plan,
  }) = _PaymentSuccessful;
}

@freezed
class SettingsPlanState with _$SettingsPlanState {
  const factory SettingsPlanState.initial() = _Initial;

  const factory SettingsPlanState.loading() = _Loading;

  const factory SettingsPlanState.error({
    @Default(null) FlowyError? error,
  }) = _Error;

  const factory SettingsPlanState.ready({
    required WorkspaceUsagePB workspaceUsage,
    required WorkspaceSubscriptionInfoPB subscriptionInfo,
    @Default(null) SubscriptionPlanPB? successfulPlanUpgrade,
    @Default(false) bool downgradeProcessing,
  }) = _Ready;
}
