import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_ai_on_boarding_bloc.freezed.dart';

class LocalAIOnBoardingBloc
    extends Bloc<LocalAIOnBoardingEvent, LocalAIOnBoardingState> {
  LocalAIOnBoardingBloc(this.userProfile)
      : super(const LocalAIOnBoardingState()) {
    _dispatch();
  }

  final UserProfilePB userProfile;

  void _dispatch() {
    on<LocalAIOnBoardingEvent>((event, emit) {
      event.when(
        started: () {
          _loadSubscriptionPlans();
        },
        didGetSubscriptionPlans: (result) {
          result.fold(
            (workspaceSubInfo) {
              final isPurchaseAILocal = workspaceSubInfo.addOns.any((addOn) {
                return addOn.type == WorkspaceAddOnPBType.AddOnAiLocal;
              });

              emit(
                state.copyWith(isPurchaseAILocal: isPurchaseAILocal),
              );
            },
            (err) {
              Log.error("Failed to get subscription plans: $err");
            },
          );
        },
      );
    });
  }

  void _loadSubscriptionPlans() {
    final payload = UserWorkspaceIdPB()..workspaceId = userProfile.workspaceId;
    UserEventGetWorkspaceSubscriptionInfo(payload).send().then((result) {
      if (!isClosed) {
        add(LocalAIOnBoardingEvent.didGetSubscriptionPlans(result));
      }
    });
  }
}

@freezed
class LocalAIOnBoardingEvent with _$LocalAIOnBoardingEvent {
  const factory LocalAIOnBoardingEvent.started() = _Started;
  const factory LocalAIOnBoardingEvent.didGetSubscriptionPlans(
    FlowyResult<WorkspaceSubscriptionInfoPB, FlowyError> result,
  ) = _LoadSubscriptionPlans;
}

@freezed
class LocalAIOnBoardingState with _$LocalAIOnBoardingState {
  const factory LocalAIOnBoardingState({
    @Default(false) bool isPurchaseAILocal,
  }) = _LocalAIOnBoardingState;
}
