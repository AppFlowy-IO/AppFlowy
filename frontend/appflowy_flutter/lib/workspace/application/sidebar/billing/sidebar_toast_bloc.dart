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
part 'sidebar_toast_bloc.freezed.dart';

class SidebarToastBloc extends Bloc<SidebarToastEvent, SidebarToastState> {
  SidebarToastBloc() : super(const SidebarToastState()) {
    // After user pays for the subscription, the subscription success listenable will be triggered
    getIt<SubscriptionSuccessListenable>().addListener(() {
      if (!isClosed) {
        Log.info("Subscription success listenable triggered");

        // Notify the user that they have switched to a new plan. It would be better if we use websocket to
        // notify the client when plan switching.
        UserEventNotifyDidSwitchPlan().send();

        _checkWorkspaceUsage();
      }
    });

    _storageListener = StoreageNotificationListener(
      onError: (error) {
        if (!isClosed) {
          add(SidebarToastEvent.receiveError(error));
        }
      },
    );

    _globalErrorListener = GlobalErrorCodeNotifier.add(
      onError: (error) {
        if (!isClosed) {
          add(SidebarToastEvent.receiveError(error));
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

    on<SidebarToastEvent>(_handleEvent);
  }

  Future<void> dispose() async {
    if (_globalErrorListener != null) {
      GlobalErrorCodeNotifier.remove(_globalErrorListener!);
    }
    await _storageListener?.stop();
    _storageListener = null;
  }

  ErrorListener? _globalErrorListener;
  StoreageNotificationListener? _storageListener;

  Future<void> _handleEvent(
    SidebarToastEvent event,
    Emitter<SidebarToastState> emit,
  ) async {
    await event.when(
      receiveError: (FlowyError error) async {},
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
              const SidebarToastEvent.updateTierIndicator(
                SidebarToastTierIndicator.proTier(),
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
              const SidebarToastEvent.updateTierIndicator(
                SidebarToastTierIndicator.aiMaxTier(),
              ),
            );
            return;
          }
        }

        // hide the tier indicator
        add(
          const SidebarToastEvent.updateTierIndicator(
            SidebarToastTierIndicator.hide(),
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
            add(SidebarToastEvent.updateWorkspaceUsage(usage));
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
class SidebarToastEvent with _$SidebarToastEvent {
  const factory SidebarToastEvent.init(
    String workspaceId,
    UserProfilePB userProfile,
  ) = _Init;
  const factory SidebarToastEvent.updateWorkspaceUsage(
    WorkspaceUsagePB usage,
  ) = _UpdateWorkspaceUsage;
  const factory SidebarToastEvent.updateTierIndicator(
    SidebarToastTierIndicator indicator,
  ) = _UpdateTierIndicator;
  const factory SidebarToastEvent.receiveError(FlowyError error) =
      _ReceiveError;
}

@freezed
class SidebarToastState with _$SidebarToastState {
  const factory SidebarToastState({
    FlowyError? error,
    UserProfilePB? userProfile,
    String? workspaceId,
    WorkspaceUsagePB? usage,
    @Default(SidebarToastTierIndicator.hide())
    SidebarToastTierIndicator tierIndicator,
  }) = _SidebarToastState;
}

@freezed
class SidebarToastTierIndicator with _$SidebarToastTierIndicator {
  // when start downloading the model
  const factory SidebarToastTierIndicator.proTier() = _proTier;
  const factory SidebarToastTierIndicator.aiMaxTier() = _aiMaxTier;
  const factory SidebarToastTierIndicator.hide() = _Hide;
}
