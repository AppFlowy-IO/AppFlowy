import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/subscription_success_listenable/subscription_success_listenable.dart';
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
  LocalAIOnBoardingBloc(
    this.userProfile,
    this.member,
    this.workspaceId,
  ) : super(const LocalAIOnBoardingState()) {
    _userService = UserBackendService(userId: userProfile.id);
    _successListenable = getIt<SubscriptionSuccessListenable>();
    _successListenable.addListener(_onPaymentSuccessful);
    _dispatch();
  }

  Future<void> _onPaymentSuccessful() async {
    if (isClosed) {
      return;
    }

    add(
      LocalAIOnBoardingEvent.paymentSuccessful(
        _successListenable.subscribedPlan,
      ),
    );
  }

  final UserProfilePB userProfile;
  final WorkspaceMemberPB member;
  final String workspaceId;
  late final IUserBackendService _userService;
  late final SubscriptionSuccessListenable _successListenable;

  void _dispatch() {
    on<LocalAIOnBoardingEvent>((event, emit) {
      event.when(
        started: () {
          _loadSubscriptionPlans();
        },
        addSubscription: (plan) async {
          emit(state.copyWith(isLoading: true));
          final result = await _userService.createSubscription(
            workspaceId,
            plan,
          );

          result.fold(
            (pl) => afLaunchUrlString(pl.paymentLink),
            (f) => Log.error(
              'Failed to fetch paymentlink for $plan: ${f.msg}',
              f,
            ),
          );
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
              Log.warn("Failed to get subscription plans: $err");
            },
          );
        },
        paymentSuccessful: (SubscriptionPlanPB? plan) {
          if (plan == SubscriptionPlanPB.AiLocal) {
            emit(state.copyWith(isPurchaseAILocal: true, isLoading: false));
          }
        },
      );
    });
  }

  void _loadSubscriptionPlans() {
    final payload = UserWorkspaceIdPB()..workspaceId = workspaceId;
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
  const factory LocalAIOnBoardingEvent.addSubscription(
    SubscriptionPlanPB plan,
  ) = _AddSubscription;
  const factory LocalAIOnBoardingEvent.paymentSuccessful(
    SubscriptionPlanPB? plan,
  ) = _PaymentSuccessful;
  const factory LocalAIOnBoardingEvent.didGetSubscriptionPlans(
    FlowyResult<WorkspaceSubscriptionInfoPB, FlowyError> result,
  ) = _LoadSubscriptionPlans;
}

@freezed
class LocalAIOnBoardingState with _$LocalAIOnBoardingState {
  const factory LocalAIOnBoardingState({
    @Default(false) bool isPurchaseAILocal,
    @Default(false) bool isLoading,
  }) = _LocalAIOnBoardingState;
}
