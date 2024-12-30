import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_bloc.freezed.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc() : super(const _Initial()) {
    on<UserProfileEvent>((event, emit) async {
      await event.when(
        started: () async => _initialize(emit),
      );
    });
  }

  Future<void> _initialize(Emitter<UserProfileState> emit) async {
    emit(const UserProfileState.loading());

    final workspaceOrFailure =
        await FolderEventGetCurrentWorkspaceSetting().send();

    final userOrFailure = await getIt<AuthService>().getUser();

    final workspaceSetting = workspaceOrFailure.fold(
      (workspaceSettingPB) => workspaceSettingPB,
      (error) => null,
    );

    final userProfile = userOrFailure.fold(
      (userProfilePB) => userProfilePB,
      (error) => null,
    );

    if (workspaceSetting == null || userProfile == null) {
      return emit(const UserProfileState.workspaceFailure());
    }

    emit(
      UserProfileState.success(
        workspaceSettings: workspaceSetting,
        userProfile: userProfile,
      ),
    );
  }
}

@freezed
class UserProfileEvent with _$UserProfileEvent {
  const factory UserProfileEvent.started() = _Started;
}

@freezed
class UserProfileState with _$UserProfileState {
  const factory UserProfileState.initial() = _Initial;
  const factory UserProfileState.loading() = _Loading;
  const factory UserProfileState.workspaceFailure() = _WorkspaceFailure;
  const factory UserProfileState.success({
    required WorkspaceSettingPB workspaceSettings,
    required UserProfilePB userProfile,
  }) = _Success;
}
