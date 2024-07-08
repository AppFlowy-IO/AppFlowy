import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbserver.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
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

          FlowyError? error;

          final subscription =
              (await UserBackendService.getWorkspaceSubscriptions()).fold(
            (s) =>
                s.items.firstWhereOrNull((i) => i.workspaceId == workspaceId) ??
                WorkspaceSubscriptionPB(
                  workspaceId: workspaceId,
                  subscriptionPlan: SubscriptionPlanPB.None,
                  isActive: true,
                ),
            (e) {
              // Not a Customer yet
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

          if (subscription == null || error != null) {
            return emit(SettingsBillingState.error(error: error));
          }

          if (!_billingPortalCompleter.isCompleted) {
            unawaited(_fetchBillingPortal());
            unawaited(
              _billingPortalCompleter.future.then(
                (result) {
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
              subscription: subscription,
              billingPortal: _billingPortal,
            ),
          );
        },
        billingPortalFetched: (billingPortal) {
          state.maybeWhen(
            orElse: () {},
            ready: (subscription, _) => emit(
              SettingsBillingState.ready(
                subscription: subscription,
                billingPortal: billingPortal,
              ),
            ),
          );
        },
        openCustomerPortal: () async {
          if (_billingPortalCompleter.isCompleted && _billingPortal != null) {
            await afLaunchUrlString(_billingPortal!.url);
          }
          await _billingPortalCompleter.future;
          if (_billingPortal != null) {
            await afLaunchUrlString(_billingPortal!.url);
          }
        },
      );
    });
  }

  late final String workspaceId;
  late final WorkspaceService _service;
  final _billingPortalCompleter =
      Completer<FlowyResult<BillingPortalPB, FlowyError>>();

  BillingPortalPB? _billingPortal;

  Future<void> _fetchBillingPortal() async {
    final billingPortalResult = await _service.getBillingPortal();
    _billingPortalCompleter.complete(billingPortalResult);
  }
}

@freezed
class SettingsBillingEvent with _$SettingsBillingEvent {
  const factory SettingsBillingEvent.started() = _Started;
  const factory SettingsBillingEvent.billingPortalFetched({
    required BillingPortalPB billingPortal,
  }) = _BillingPortalFetched;
  const factory SettingsBillingEvent.openCustomerPortal() = _OpenCustomerPortal;
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
    required WorkspaceSubscriptionPB subscription,
    required BillingPortalPB? billingPortal,
  }) = _Ready;

  @override
  List<Object?> get props => maybeWhen(
        orElse: () => const [],
        error: (error) => [error],
        ready: (subscription, billingPortal) => [subscription, billingPortal],
      );
}
