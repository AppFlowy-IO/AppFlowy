import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ChatUserCubit is responsible for fetching and storing the user profile
class ChatUserCubit extends Cubit<ChatUserState> {
  ChatUserCubit() : super(ChatUserLoadingState()) {
    fetchUserProfile();
  }

  /// Fetches the user profile from the AuthService
  Future<void> fetchUserProfile() async {
    emit(ChatUserLoadingState());
    final userOrFailure = await getIt<AuthService>().getUser();

    userOrFailure.fold(
      (userProfile) => emit(ChatUserSuccessState(userProfile)),
      (error) => emit(ChatUserFailureState(error)),
    );
  }

  bool supportSelectSource() {
    if (state is ChatUserSuccessState) {
      final userProfile = (state as ChatUserSuccessState).userProfile;
      if (userProfile.userAuthType == AuthTypePB.Server) {
        return true;
      }
    }
    return false;
  }

  bool isValueWorkspace() {
    if (state is ChatUserSuccessState) {
      final userProfile = (state as ChatUserSuccessState).userProfile;
      return userProfile.workspaceType == WorkspaceTypePB.LocalW &&
          userProfile.userAuthType != AuthTypePB.Local;
    }
    return false;
  }

  /// Refreshes the user profile data
  Future<void> refresh() async {
    await fetchUserProfile();
  }
}

/// Base state class for ChatUserCubit
abstract class ChatUserState extends Equatable {
  const ChatUserState();

  @override
  List<Object?> get props => [];
}

/// Loading state when fetching user profile
class ChatUserLoadingState extends ChatUserState {}

/// Success state when user profile is fetched successfully
class ChatUserSuccessState extends ChatUserState {
  const ChatUserSuccessState(this.userProfile);
  final UserProfilePB userProfile;

  @override
  List<Object?> get props => [userProfile];
}

/// Failure state when fetching user profile fails
class ChatUserFailureState extends ChatUserState {
  const ChatUserFailureState(this.error);
  final FlowyError error;

  @override
  List<Object?> get props => [error];
}
