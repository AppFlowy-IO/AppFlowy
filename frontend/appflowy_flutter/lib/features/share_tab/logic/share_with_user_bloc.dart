import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/data/repositories/share_with_user_repository.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_with_user_bloc.freezed.dart';

class ShareWithUserBloc extends Bloc<ShareWithUserEvent, ShareWithUserState> {
  ShareWithUserBloc({
    required this.repository,
    required this.pageId,
    required this.workspaceId,
  }) : super(ShareWithUserState.initial()) {
    on<Initial>(_onInitial);
    on<GetSharedUsers>(_onGetSharedUsers);
    on<ShareWithUser>(_onShare);
    on<RemoveUser>(_onRemove);
    on<UpdateAccessLevel>(_onUpdateAccessLevel);
    on<UpdateGeneralAccess>(_onUpdateGeneralAccess);
    on<CopyLink>(_onCopyLink);
    on<SearchAvailableUsers>(_onSearchAvailableUsers);
    on<TurnIntoMember>(_onTurnIntoMember);
  }

  final ShareWithUserRepository repository;
  final String workspaceId;
  final String pageId;

  Future<void> _onInitial(
    Initial event,
    Emitter<ShareWithUserState> emit,
  ) async {
    if (!FeatureFlag.sharedSection.isOn) {
      return;
    }

    final result = await UserBackendService.getCurrentUserProfile();
    final currentUser = result.fold(
      (user) => user,
      (error) => null,
    );

    final shareLink = ShareConstants.buildShareUrl(
      workspaceId: workspaceId,
      viewId: pageId,
    );

    final users = await _getLatestSharedUsersOrCurrentUsers();

    emit(
      state.copyWith(
        currentUser: currentUser,
        shareLink: shareLink,
        users: users,
      ),
    );
  }

  Future<void> _onGetSharedUsers(
    GetSharedUsers event,
    Emitter<ShareWithUserState> emit,
  ) async {
    if (!FeatureFlag.sharedSection.isOn) {
      return;
    }

    emit(
      state.copyWith(
        errorMessage: '',
        initialResult: null,
        shareResult: null,
        removeResult: null,
        updateAccessLevelResult: null,
        turnIntoMemberResult: null,
      ),
    );

    final result = await repository.getSharedUsersInPage(
      pageId: pageId,
    );

    result.fold(
      (users) => emit(
        state.copyWith(
          users: users,
          initialResult: FlowySuccess(null),
        ),
      ),
      (error) => emit(
        state.copyWith(
          errorMessage: error.msg,
          initialResult: FlowyFailure(error),
        ),
      ),
    );
  }

  Future<void> _onShare(
    ShareWithUser event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(
      state.copyWith(
        errorMessage: '',
        shareResult: null,
        turnIntoMemberResult: null,
        removeResult: null,
        updateAccessLevelResult: null,
      ),
    );

    final result = await repository.sharePageWithUser(
      pageId: pageId,
      accessLevel: event.accessLevel,
      emails: event.emails,
    );

    await result.fold(
      (_) async {
        final users = await _getLatestSharedUsersOrCurrentUsers();

        emit(
          state.copyWith(
            shareResult: FlowySuccess(null),
            users: users,
          ),
        );
      },
      (error) async {
        emit(
          state.copyWith(
            errorMessage: error.msg,
            shareResult: FlowyFailure(error),
          ),
        );
      },
    );
  }

  Future<void> _onRemove(
    RemoveUser event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(
      state.copyWith(
        errorMessage: '',
        removeResult: null,
        shareResult: null,
        updateAccessLevelResult: null,
        turnIntoMemberResult: null,
      ),
    );

    final result = await repository.removeSharedUserFromPage(
      pageId: pageId,
      emails: event.emails,
    );

    await result.fold(
      (_) async {
        final users = await _getLatestSharedUsersOrCurrentUsers();
        emit(
          state.copyWith(
            removeResult: FlowySuccess(null),
            users: users,
          ),
        );
      },
      (error) async {
        emit(
          state.copyWith(
            isLoading: false,
            removeResult: FlowyFailure(error),
          ),
        );
      },
    );
  }

  Future<void> _onUpdateAccessLevel(
    UpdateAccessLevel event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(
      state.copyWith(
        updateAccessLevelResult: null,
      ),
    );

    final result = await repository.sharePageWithUser(
      pageId: pageId,
      accessLevel: event.accessLevel,
      emails: [event.email],
    );

    await result.fold(
      (_) async {
        final users = await _getLatestSharedUsersOrCurrentUsers();
        emit(
          state.copyWith(
            updateAccessLevelResult: FlowySuccess(null),
            users: users,
          ),
        );
      },
      (error) async {
        emit(
          state.copyWith(
            errorMessage: error.msg,
            isLoading: false,
          ),
        );
      },
    );
  }

  void _onUpdateGeneralAccess(
    UpdateGeneralAccess event,
    Emitter<ShareWithUserState> emit,
  ) {
    emit(
      state.copyWith(
        generalAccessRole: event.accessLevel,
      ),
    );
  }

  void _onCopyLink(CopyLink event, Emitter<ShareWithUserState> emit) {
    getIt<ClipboardService>().setData(
      ClipboardServiceData(
        plainText: event.link,
      ),
    );

    emit(
      state.copyWith(
        linkCopied: true,
      ),
    );
  }

  Future<void> _onSearchAvailableUsers(
    SearchAvailableUsers event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(
      state.copyWith(
        errorMessage: '',
      ),
    );

    final result = await repository.getAvailableSharedUsers(pageId: pageId);

    result.fold(
      (users) {
        // filter by email and name
        final availableUsers = users.where((user) {
          final query = event.query.toLowerCase();
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
        emit(
          state.copyWith(
            availableUsers: availableUsers,
          ),
        );
      },
      (error) => emit(
        state.copyWith(
          errorMessage: error.msg,
          availableUsers: [],
        ),
      ),
    );
  }

  Future<void> _onTurnIntoMember(
    TurnIntoMember event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(
      state.copyWith(
        turnIntoMemberResult: null,
        errorMessage: '',
        removeResult: null,
        shareResult: null,
        updateAccessLevelResult: null,
      ),
    );

    final result = await repository.changeRole(
      pageId: pageId,
      email: event.email,
      role: ShareRole.member,
    );

    await result.fold(
      (_) async {
        final users = await _getLatestSharedUsersOrCurrentUsers();
        emit(
          state.copyWith(
            turnIntoMemberResult: FlowySuccess(null),
            users: users,
          ),
        );
      },
      (error) async {
        emit(
          state.copyWith(
            errorMessage: error.msg,
            turnIntoMemberResult: FlowyFailure(error),
          ),
        );
      },
    );
  }

  Future<SharedUsers> _getLatestSharedUsersOrCurrentUsers() async {
    final shareResult = await repository.getSharedUsersInPage(
      pageId: pageId,
    );
    return shareResult.fold(
      (users) => users,
      (error) => state.users,
    );
  }
}

@freezed
class ShareWithUserEvent with _$ShareWithUserEvent {
  /// Initializes the bloc.
  const factory ShareWithUserEvent.init() = Initial;

  /// Loads the shared users for the page.
  const factory ShareWithUserEvent.getSharedUsers() = GetSharedUsers;

  /// Invites the users to the page.
  const factory ShareWithUserEvent.share({
    required List<String> emails,
    required ShareAccessLevel accessLevel,
  }) = ShareWithUser;

  /// Removes the users from the page.
  const factory ShareWithUserEvent.remove({
    required List<String> emails,
  }) = RemoveUser;

  /// Updates the access level of the user.
  const factory ShareWithUserEvent.updateAccessLevel({
    required String email,
    required ShareAccessLevel accessLevel,
  }) = UpdateAccessLevel;

  /// Updates the general access role for all users.
  const factory ShareWithUserEvent.updateGeneralAccess({
    required ShareAccessLevel accessLevel,
  }) = UpdateGeneralAccess;

  /// Copies the link to the clipboard.
  const factory ShareWithUserEvent.copyLink({
    required String link,
  }) = CopyLink;

  /// Searches available users by name or email.
  const factory ShareWithUserEvent.searchAvailableUsers({
    required String query,
  }) = SearchAvailableUsers;

  /// Turns the user into a member.
  const factory ShareWithUserEvent.turnIntoMember({
    required String email,
  }) = TurnIntoMember;
}

@freezed
class ShareWithUserState with _$ShareWithUserState {
  const factory ShareWithUserState({
    @Default(null) UserProfilePB? currentUser,
    @Default([]) SharedUsers users,
    @Default([]) SharedUsers availableUsers,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default('') String shareLink,
    ShareAccessLevel? generalAccessRole,
    @Default(false) bool linkCopied,
    @Default(null) FlowyResult<void, FlowyError>? initialResult,
    @Default(null) FlowyResult<void, FlowyError>? shareResult,
    @Default(null) FlowyResult<void, FlowyError>? removeResult,
    @Default(null) FlowyResult<void, FlowyError>? updateAccessLevelResult,
    @Default(null) FlowyResult<void, FlowyError>? turnIntoMemberResult,
  }) = _ShareWithUserState;

  factory ShareWithUserState.initial() => const ShareWithUserState();
}
