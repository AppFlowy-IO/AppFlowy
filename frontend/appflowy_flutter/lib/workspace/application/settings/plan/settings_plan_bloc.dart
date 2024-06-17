import 'package:flutter/foundation.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/subscription_success_listenable/subscription_success_listenable.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbserver.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
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
        started: (withShowSuccessful) async {
          emit(const SettingsPlanState.loading());

          final snapshots = await Future.wait([
            _service.getWorkspaceUsage(),
            UserBackendService.getWorkspaceSubscriptions(),
            _service.getBillingPortal(),
          ]);

          FlowyError? error;

          final usageResult = snapshots.first.fold(
            (s) => s as WorkspaceUsagePB,
            (f) {
              error = f;
              return null;
            },
          );

          final subscription = snapshots[1].fold(
            (s) =>
                (s as RepeatedWorkspaceSubscriptionPB)
                    .items
                    .firstWhereOrNull((i) => i.workspaceId == workspaceId) ??
                WorkspaceSubscriptionPB(
                  workspaceId: workspaceId,
                  subscriptionPlan: SubscriptionPlanPB.None,
                  isActive: true,
                ),
            (f) {
              error = f;
              return null;
            },
          );

          final billingPortalResult = snapshots.last;
          final billingPortal = billingPortalResult.fold(
            (s) => s as BillingPortalPB,
            (e) {
              // Not a customer yet
              if (e.code == ErrorCode.InvalidParams) {
                return BillingPortalPB();
              }

              error = e;
              return null;
            },
          );

          if (usageResult == null ||
              subscription == null ||
              billingPortal == null ||
              error != null) {
            return emit(SettingsPlanState.error(error: error));
          }

          emit(
            SettingsPlanState.ready(
              workspaceUsage: usageResult,
              subscription: subscription,
              billingPortal: billingPortal,
              showSuccessDialog: withShowSuccessful,
            ),
          );

          if (withShowSuccessful) {
            emit(
              SettingsPlanState.ready(
                workspaceUsage: usageResult,
                subscription: subscription,
                billingPortal: billingPortal,
              ),
            );
          }
        },
        addSubscription: (plan) async {
          final result = await _userService.createSubscription(
            workspaceId,
            SubscriptionPlanPB.Pro,
          );

          result.fold(
            (pl) => afLaunchUrlString(pl.paymentLink),
            (f) => Log.error(f.msg, f),
          );
        },
        cancelSubscription: () async {
          await _userService.cancelSubscription(workspaceId);
          add(const SettingsPlanEvent.started());
        },
        paymentSuccessful: () {
          final readyState = state.mapOrNull(ready: (state) => state);
          if (readyState == null) {
            return;
          }

          add(const SettingsPlanEvent.started(withShowSuccessful: true));
        },
      );
    });
  }

  late final String workspaceId;
  late final WorkspaceService _service;
  late final IUserBackendService _userService;
  late final SubscriptionSuccessListenable _successListenable;

  void _onPaymentSuccessful() {
    add(const SettingsPlanEvent.paymentSuccessful());
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
    @Default(false) bool withShowSuccessful,
  }) = _Started;
  const factory SettingsPlanEvent.addSubscription(SubscriptionPlanPB plan) =
      _AddSubscription;
  const factory SettingsPlanEvent.cancelSubscription() = _CancelSubscription;
  const factory SettingsPlanEvent.paymentSuccessful() = _PaymentSuccessful;
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
    required WorkspaceSubscriptionPB subscription,
    required BillingPortalPB? billingPortal,
    @Default(false) bool showSuccessDialog,
  }) = _Ready;
}
