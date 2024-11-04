import 'dart:async';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/file_storage/file_storage_listener.dart';
import 'package:appflowy/workspace/application/subscription_success_listenable/subscription_success_listenable.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/dispatch/error.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'sidebar_plan_bloc.freezed.dart';

class SidebarPlanBloc extends Bloc<SidebarPlanEvent, SidebarPlanState> {
  SidebarPlanBloc() : super(const SidebarPlanState()) {
    // 1. Listen to user subscription payment callback. After user client 'Open AppFlowy', this listenable will be triggered.
    _subscriptionListener = getIt<SubscriptionSuccessListenable>();
    _subscriptionListener.addListener(_onPaymentSuccessful);

    // 2. Listen to the storage notification
    _storageListener = StoreageNotificationListener(
      onError: (error) {
        if (!isClosed) {
          add(SidebarPlanEvent.receiveError(error));
        }
      },
    );

    // 3. Listen to specific error codes
    _globalErrorListener = GlobalErrorCodeNotifier.add(
      onError: (error) {
        if (!isClosed) {
          add(SidebarPlanEvent.receiveError(error));
        }
      },
      onErrorIf: (error) {
        const relevantErrorCodes = {
          ErrorCode.AIResponseLimitExceeded,
          ErrorCode.FileStorageLimitExceeded,
        };
        return relevantErrorCodes.contains(error.code);
      },
    );

    on<SidebarPlanEvent>(_handleEvent);
  }

  void _onPaymentSuccessful() {
    final plan = _subscriptionListener.subscribedPlan;
    Log.info("Subscription success listenable triggered: $plan");

    if (!isClosed) {
      // Notify the user that they have switched to a new plan. It would be better if we use websocket to
      // notify the client when plan switching.
      if (state.workspaceId != null) {
        final payload = SuccessWorkspaceSubscriptionPB(
          workspaceId: state.workspaceId,
        );

        if (plan != null) {
          payload.plan = plan;
        }

        UserEventNotifyDidSwitchPlan(payload).send().then((result) {
          result.fold(
            // After the user has switched to a new plan, we need to refresh the workspace usage.
            (_) => _checkWorkspaceUsage(),
            (error) => Log.error("NotifyDidSwitchPlan failed: $error"),
          );
        });
      } else {
        Log.error(
          "Unexpected empty workspace id when subscription success listenable triggered. It should not happen. If happens, it must be a bug",
        );
      }
    }
  }

  Future<void> dispose() async {
    if (_globalErrorListener != null) {
      GlobalErrorCodeNotifier.remove(_globalErrorListener!);
    }
    _subscriptionListener.removeListener(_onPaymentSuccessful);
    await _storageListener?.stop();
    _storageListener = null;
  }

  ErrorListener? _globalErrorListener;
  StoreageNotificationListener? _storageListener;
  late final SubscriptionSuccessListenable _subscriptionListener;

  Future<void> _handleEvent(
    SidebarPlanEvent event,
    Emitter<SidebarPlanState> emit,
  ) async {
    await event.when(
      receiveError: (FlowyError error) async {
        if (error.code == ErrorCode.AIResponseLimitExceeded) {
          emit(
            state.copyWith(
              tierIndicator: const SidebarToastTierIndicator.aiMaxiLimitHit(),
            ),
          );
        } else if (error.code == ErrorCode.FileStorageLimitExceeded) {
          emit(
            state.copyWith(
              tierIndicator: const SidebarToastTierIndicator.storageLimitHit(),
            ),
          );
        } else {
          Log.error("Unhandle Unexpected error: $error");
        }
      },
      init: (String workspaceId, UserProfilePB userProfile) {
        emit(
          state.copyWith(
            workspaceId: workspaceId,
            userProfile: userProfile,
          ),
        );

        _checkWorkspaceUsage();
      },
      updateWorkspaceUsage: (WorkspaceUsagePB usage) {
        // when the user's storage bytes are limited, show the upgrade tier button
        if (!usage.storageBytesUnlimited) {
          if (usage.storageBytes >= usage.storageBytesLimit) {
            add(
              const SidebarPlanEvent.updateTierIndicator(
                SidebarToastTierIndicator.storageLimitHit(),
              ),
            );

            /// Checks if the user needs to upgrade to the Pro Plan.
            /// If the user needs to upgrade, it means they don't need to enable the AI max tier.
            /// This function simply returns without performing any further actions.
            return;
          }
        }

        // when user's AI responses are limited, show the AI max tier button.
        if (!usage.aiResponsesUnlimited) {
          if (usage.aiResponsesCount >= usage.aiResponsesCountLimit) {
            add(
              const SidebarPlanEvent.updateTierIndicator(
                SidebarToastTierIndicator.aiMaxiLimitHit(),
              ),
            );
            return;
          }
        }

        // hide the tier indicator
        add(
          const SidebarPlanEvent.updateTierIndicator(
            SidebarToastTierIndicator.loading(),
          ),
        );
      },
      updateTierIndicator: (SidebarToastTierIndicator indicator) {
        emit(
          state.copyWith(
            tierIndicator: indicator,
          ),
        );
      },
    );
  }

  void _checkWorkspaceUsage() {
    if (state.workspaceId != null) {
      final payload = UserWorkspaceIdPB(workspaceId: state.workspaceId!);
      UserEventGetWorkspaceUsage(payload).send().then((result) {
        result.fold(
          (usage) {
            add(SidebarPlanEvent.updateWorkspaceUsage(usage));
          },
          (error) {
            Log.error("Failed to get workspace usage, error: $error");
          },
        );
      });
    }
  }
}

@freezed
class SidebarPlanEvent with _$SidebarPlanEvent {
  const factory SidebarPlanEvent.init(
    String workspaceId,
    UserProfilePB userProfile,
  ) = _Init;
  const factory SidebarPlanEvent.updateWorkspaceUsage(
    WorkspaceUsagePB usage,
  ) = _UpdateWorkspaceUsage;
  const factory SidebarPlanEvent.updateTierIndicator(
    SidebarToastTierIndicator indicator,
  ) = _UpdateTierIndicator;
  const factory SidebarPlanEvent.receiveError(FlowyError error) = _ReceiveError;
}

@freezed
class SidebarPlanState with _$SidebarPlanState {
  const factory SidebarPlanState({
    FlowyError? error,
    UserProfilePB? userProfile,
    String? workspaceId,
    WorkspaceUsagePB? usage,
    @Default(SidebarToastTierIndicator.loading())
    SidebarToastTierIndicator tierIndicator,
  }) = _SidebarPlanState;
}

@freezed
class SidebarToastTierIndicator with _$SidebarToastTierIndicator {
  // when start downloading the model
  const factory SidebarToastTierIndicator.storageLimitHit() = _StorageLimitHit;
  const factory SidebarToastTierIndicator.aiMaxiLimitHit() = _aiMaxLimitHit;
  const factory SidebarToastTierIndicator.loading() = _Loading;
}
