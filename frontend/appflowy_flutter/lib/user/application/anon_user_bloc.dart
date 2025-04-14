import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'anon_user_bloc.freezed.dart';

class AnonUserBloc extends Bloc<AnonUserEvent, AnonUserState> {
  AnonUserBloc() : super(AnonUserState.initial()) {
    on<AnonUserEvent>((event, emit) async {
      await event.when(
        initial: () async {},
        didLoadAnonUsers: (List<UserProfilePB> anonUsers) {
          emit(state.copyWith(anonUsers: anonUsers));
        },
        openAnonUser: (anonUser) async {
          await UserBackendService.openAnonUser();
          emit(state.copyWith(openedAnonUser: anonUser));
        },
      );
    });
  }
}

@freezed
class AnonUserEvent with _$AnonUserEvent {
  const factory AnonUserEvent.initial() = _Initial;
  const factory AnonUserEvent.didLoadAnonUsers(
    List<UserProfilePB> historicalUsers,
  ) = _DidLoadHistoricalUsers;
  const factory AnonUserEvent.openAnonUser(UserProfilePB anonUser) =
      _OpenHistoricalUser;
}

@freezed
class AnonUserState with _$AnonUserState {
  const factory AnonUserState({
    required List<UserProfilePB> anonUsers,
    required UserProfilePB? openedAnonUser,
  }) = _AnonUserState;

  factory AnonUserState.initial() => const AnonUserState(
        anonUsers: [],
        openedAnonUser: null,
      );
}
