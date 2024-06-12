import 'package:flutter/foundation.dart';

import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbserver.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_billing_bloc.freezed.dart';

class SettingsBillingBloc
    extends Bloc<SettingsBillingEvent, SettingsBillingState> {
  SettingsBillingBloc({
    required this.workspaceId,
  }) : super(const _Initial()) {
    _service = WorkspaceService(workspaceId: workspaceId);

    on<SettingsBillingEvent>((event, emit) async {
      await event.when(
        started: () async {
          emit(const SettingsBillingState.loading());

          final snapshots = await Future.wait([
            UserBackendService.getWorkspaceSubscriptions(),
            _service.getBillingPortal(),
          ]);

          FlowyError? error;

          final subscription = snapshots.first.fold(
            (s) =>
                (s as RepeatedWorkspaceSubscriptionPB)
                    .items
                    .firstWhereOrNull((i) => i.workspaceId == workspaceId) ??
                WorkspaceSubscriptionPB(
                  workspaceId: workspaceId,
                  subscriptionPlan: SubscriptionPlanPB.None,
                  isActive: true,
                ),
            (e) {
              // Not a Cjstomer yet
              if (e.code == ErrorCode.InvalidParams) {
                return WorkspaceSubscriptionPB(
                  workspaceId: workspaceId,
                  subscriptionPlan: SubscriptionPlanPB.None,
                  isActive: true,
                );
              }

              error = e;
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

          if (subscription == null || billingPortal == null || error != null) {
            return emit(SettingsBillingState.error(error: error));
          }

          emit(
            SettingsBillingState.ready(
              subscription: subscription,
              billingPortal: billingPortal,
            ),
          );
        },
      );
    });
  }

  late final String workspaceId;
  late final WorkspaceService _service;
}

@freezed
class SettingsBillingEvent with _$SettingsBillingEvent {
  const factory SettingsBillingEvent.started() = _Started;
}

@freezed
class SettingsBillingState with _$SettingsBillingState {
  const factory SettingsBillingState.initial() = _Initial;

  const factory SettingsBillingState.loading() = _Loading;

  const factory SettingsBillingState.error({
    @Default(null) FlowyError? error,
  }) = _Error;

  const factory SettingsBillingState.ready({
    required WorkspaceSubscriptionPB subscription,
    required BillingPortalPB? billingPortal,
  }) = _Ready;
}
