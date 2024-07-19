import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/application/subscription_success_listenable/subscription_success_listenable.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbserver.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fixnum/fixnum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'settings_billing_bloc.freezed.dart';

class SettingsBillingBloc
    extends Bloc<SettingsBillingEvent, SettingsBillingState> {
  SettingsBillingBloc({
    required this.workspaceId,
    required Int64 userId,
  }) : super(const _Initial()) {
    _userService = UserBackendService(userId: userId);
    _service = WorkspaceService(workspaceId: workspaceId);
    _successListenable = getIt<SubscriptionSuccessListenable>();
    _successListenable.addListener(_onPaymentSuccessful);

    on<SettingsBillingEvent>((event, emit) async {
      await event.when(
        started: () async {
          emit(const SettingsBillingState.loading());

          FlowyError? error;

<<<<<<< HEAD
          final result = await UserBackendService.getWorkspaceSubscriptionInfo(
            workspaceId,
          );
=======
          final subscription = snapshots.first.fold(
            (s) =>
                (s as RepeatedWorkspaceSubscriptionPB)
                    .items
                    .firstWhereOrNull((i) => i.workspaceId == workspaceId) ??
                WorkspaceSubscriptionPB(
                  workspaceId: workspaceId,
                  subscriptionPlan: SubscriptionPlanPB.Free,
                  isActive: true,
                ),
            (e) {
              // Not a Cjstomer yet
              if (e.code == ErrorCode.InvalidParams) {
                return WorkspaceSubscriptionPB(
                  workspaceId: workspaceId,
                  subscriptionPlan: SubscriptionPlanPB.Free,
                  isActive: true,
                );
              }
>>>>>>> billing_error_code

          final subscriptionInfo = result.fold(
            (s) => s,
            (e) {
              error = e;
              return null;
            },
          );

          if (subscriptionInfo == null || error != null) {
            return emit(SettingsBillingState.error(error: error));
          }

          if (!_billingPortalCompleter.isCompleted) {
            unawaited(_fetchBillingPortal());
            unawaited(
              _billingPortalCompleter.future.then(
                (result) {
                  if (isClosed) return;

                  result.fold(
                    (portal) {
                      _billingPortal = portal;
                      add(
                        SettingsBillingEvent.billingPortalFetched(
                          billingPortal: portal,
                        ),
                      );
                    },
                    (e) => Log.error('Error fetching billing portal: $e'),
                  );
                },
              ),
            );
          }

          emit(
            SettingsBillingState.ready(
              subscriptionInfo: subscriptionInfo,
              billingPortal: _billingPortal,
            ),
          );
        },
        billingPortalFetched: (billingPortal) async => state.maybeWhen(
          orElse: () {},
          ready: (subscriptionInfo, _, plan, isLoading) => emit(
            SettingsBillingState.ready(
              subscriptionInfo: subscriptionInfo,
              billingPortal: billingPortal,
              successfulPlanUpgrade: plan,
              isLoading: isLoading,
            ),
          ),
        ),
        openCustomerPortal: () async {
          if (_billingPortalCompleter.isCompleted && _billingPortal != null) {
            return afLaunchUrlString(_billingPortal!.url);
          }
          await _billingPortalCompleter.future;
          if (_billingPortal != null) {
            await afLaunchUrlString(_billingPortal!.url);
          }
        },
        addSubscription: (plan) async {
          final result =
              await _userService.createSubscription(workspaceId, plan);

          result.fold(
            (link) => afLaunchUrlString(link.paymentLink),
            (f) => Log.error(f.msg, f),
          );
        },
        cancelSubscription: (plan) async {
          final s = state.mapOrNull(ready: (s) => s);
          if (s == null) {
            return;
          }

          emit(s.copyWith(isLoading: true));

          final result =
              await _userService.cancelSubscription(workspaceId, plan);
          final successOrNull = result.fold(
            (_) => true,
            (f) {
              Log.error(
                'Failed to cancel subscription of ${plan.label}: ${f.msg}',
                f,
              );
              return null;
            },
          );

          if (successOrNull != true) {
            return;
          }

          final subscriptionInfo = state.mapOrNull(
            ready: (s) => s.subscriptionInfo,
          );

          // This is impossible, but for good measure
          if (subscriptionInfo == null) {
            return;
          }

          subscriptionInfo.freeze();
          final newInfo = subscriptionInfo.rebuild((value) {
            if (plan.isAddOn) {
              value.addOns.removeWhere(
                (addon) => addon.addOnSubscription.subscriptionPlan == plan,
              );
            }

            if (plan == WorkspacePlanPB.ProPlan &&
                value.plan == WorkspacePlanPB.ProPlan) {
              value.plan = WorkspacePlanPB.FreePlan;
              value.planSubscription.freeze();
              value.planSubscription = value.planSubscription.rebuild((sub) {
                sub.status = WorkspaceSubscriptionStatusPB.Active;
                sub.subscriptionPlan = SubscriptionPlanPB.None;
              });
            }
          });

          emit(
            SettingsBillingState.ready(
              subscriptionInfo: newInfo,
              billingPortal: _billingPortal,
            ),
          );
        },
        paymentSuccessful: (plan) async {
          final result = await UserBackendService.getWorkspaceSubscriptionInfo(
            workspaceId,
          );

          final subscriptionInfo = result.toNullable();
          if (subscriptionInfo != null) {
            emit(
              SettingsBillingState.ready(
                subscriptionInfo: subscriptionInfo,
                billingPortal: _billingPortal,
              ),
            );
          }
        },
        updatePeriod: (plan, interval) async {
          final s = state.mapOrNull(ready: (s) => s);
          if (s == null) {
            return;
          }

          emit(s.copyWith(isLoading: true));

          final result = await _userService.updateSubscriptionPeriod(
            workspaceId,
            plan,
            interval,
          );
          final successOrNull = result.fold((_) => true, (f) {
            Log.error(
              'Failed to update subscription period of ${plan.label}: ${f.msg}',
              f,
            );
            return null;
          });

          if (successOrNull != true) {
            return emit(s.copyWith(isLoading: false));
          }

          // Fetch new subscription info
          final newResult =
              await UserBackendService.getWorkspaceSubscriptionInfo(
            workspaceId,
          );

          final newSubscriptionInfo = newResult.toNullable();
          if (newSubscriptionInfo != null) {
            emit(
              SettingsBillingState.ready(
                subscriptionInfo: newSubscriptionInfo,
                billingPortal: _billingPortal,
              ),
            );
          }
        },
      );
    });
  }

  late final String workspaceId;
  late final WorkspaceService _service;
  late final UserBackendService _userService;
  final _billingPortalCompleter =
      Completer<FlowyResult<BillingPortalPB, FlowyError>>();

  BillingPortalPB? _billingPortal;
  late final SubscriptionSuccessListenable _successListenable;

  @override
  Future<void> close() {
    _successListenable.removeListener(_onPaymentSuccessful);
    return super.close();
  }

  Future<void> _fetchBillingPortal() async {
    final billingPortalResult = await _service.getBillingPortal();
    _billingPortalCompleter.complete(billingPortalResult);
  }

  Future<void> _onPaymentSuccessful() async => add(
        SettingsBillingEvent.paymentSuccessful(
          plan: _successListenable.subscribedPlan,
        ),
      );
}

@freezed
class SettingsBillingEvent with _$SettingsBillingEvent {
  const factory SettingsBillingEvent.started() = _Started;

  const factory SettingsBillingEvent.billingPortalFetched({
    required BillingPortalPB billingPortal,
  }) = _BillingPortalFetched;

  const factory SettingsBillingEvent.openCustomerPortal() = _OpenCustomerPortal;

  const factory SettingsBillingEvent.addSubscription(SubscriptionPlanPB plan) =
      _AddSubscription;

  const factory SettingsBillingEvent.cancelSubscription(
    SubscriptionPlanPB plan,
  ) = _CancelSubscription;

  const factory SettingsBillingEvent.paymentSuccessful({
    SubscriptionPlanPB? plan,
  }) = _PaymentSuccessful;

  const factory SettingsBillingEvent.updatePeriod({
    required SubscriptionPlanPB plan,
    required RecurringIntervalPB interval,
  }) = _UpdatePeriod;
}

@freezed
class SettingsBillingState extends Equatable with _$SettingsBillingState {
  const SettingsBillingState._();

  const factory SettingsBillingState.initial() = _Initial;

  const factory SettingsBillingState.loading() = _Loading;

  const factory SettingsBillingState.error({
    @Default(null) FlowyError? error,
  }) = _Error;

  const factory SettingsBillingState.ready({
    required WorkspaceSubscriptionInfoPB subscriptionInfo,
    required BillingPortalPB? billingPortal,
    @Default(null) SubscriptionPlanPB? successfulPlanUpgrade,
    @Default(false) bool isLoading,
  }) = _Ready;

  @override
  List<Object?> get props => maybeWhen(
        orElse: () => const [],
        error: (error) => [error],
        ready: (subscription, billingPortal, plan, isLoading) => [
          subscription,
          billingPortal,
          plan,
          isLoading,
          ...subscription.addOns,
        ],
      );
}
