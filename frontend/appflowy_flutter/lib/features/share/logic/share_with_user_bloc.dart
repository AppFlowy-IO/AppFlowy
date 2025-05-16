import 'package:appflowy/features/share/data/models/share_role.dart';
import 'package:appflowy/features/share/data/models/shared_user.dart';
import 'package:appflowy/features/share/data/repositories/share_repository.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
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
    on<UpdateUserRole>(_onUpdateRole);
    on<UpdateGeneralAccess>(_onUpdateGeneralAccess);
    on<CopyLink>(_onCopyLink);
  }

  final ShareRepository repository;
  final String workspaceId;
  final String pageId;

  Future<void> _onInitial(
    Initial event,
    Emitter<ShareWithUserState> emit,
  ) async {
    final result = await UserBackendService.getCurrentUserProfile();
    final currentUser = result.fold(
      (user) => user,
      (error) => null,
    );

    final shareLink = ShareConstants.buildShareUrl(
      workspaceId: workspaceId,
      viewId: pageId,
    );

    emit(
      state.copyWith(
        currentUser: currentUser,
        shareLink: shareLink,
      ),
    );

    add(const ShareWithUserEvent.getSharedUsers());
  }

  Future<void> _onGetSharedUsers(
    GetSharedUsers event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: '',
        initialResult: null,
      ),
    );

    final result = await repository.getUsersInSharedPage(
      pageId: pageId,
    );

    result.fold(
      (users) => emit(
        state.copyWith(
          users: users,
          isLoading: false,
          initialResult: FlowySuccess(null),
        ),
      ),
      (error) => emit(
        state.copyWith(
          errorMessage: error.msg,
          isLoading: false,
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
      ),
    );

    final result = await repository.sharePageWithUser(
      pageId: pageId,
      role: event.role,
      emails: event.emails,
    );

    result.fold(
      (_) {
        emit(
          state.copyWith(
            shareResult: FlowySuccess(null),
          ),
        );

        add(
          const ShareWithUserEvent.getSharedUsers(),
        );
      },
      (error) {
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
        removeResult: null,
      ),
    );

    final result = await repository.removeUserFromPage(
      pageId: pageId,
      emails: event.emails,
    );

    result.fold(
      (_) {
        emit(
          state.copyWith(
            removeResult: FlowySuccess(null),
          ),
        );

        add(
          const ShareWithUserEvent.getSharedUsers(),
        );
      },
      (error) {
        emit(
          state.copyWith(
            isLoading: false,
            removeResult: FlowyFailure(error),
          ),
        );
      },
    );
  }

  Future<void> _onUpdateRole(
    UpdateUserRole event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(
      state.copyWith(
        updateRoleResult: null,
      ),
    );

    final result = await repository.sharePageWithUser(
      pageId: pageId,
      role: event.role,
      emails: [event.email],
    );

    result.fold(
      (_) {
        emit(
          state.copyWith(
            updateRoleResult: FlowySuccess(null),
          ),
        );

        add(
          const ShareWithUserEvent.getSharedUsers(),
        );
      },
      (error) => emit(
        state.copyWith(
          errorMessage: error.msg,
          isLoading: false,
        ),
      ),
    );
  }

  void _onUpdateGeneralAccess(
    UpdateGeneralAccess event,
    Emitter<ShareWithUserState> emit,
  ) {
    emit(
      state.copyWith(
        generalAccessRole: event.role,
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
    required ShareRole role,
  }) = ShareWithUser;

  /// Removes the users from the page.
  const factory ShareWithUserEvent.remove({
    required List<String> emails,
  }) = RemoveUser;

  /// Updates the role of the user.
  const factory ShareWithUserEvent.updateRole({
    required String email,
    required ShareRole role,
  }) = UpdateUserRole;

  /// Updates the general access role for all users.
  const factory ShareWithUserEvent.updateGeneralAccess({
    required ShareRole role,
  }) = UpdateGeneralAccess;

  /// Copies the link to the clipboard.
  const factory ShareWithUserEvent.copyLink({
    required String link,
  }) = CopyLink;
}

@freezed
class ShareWithUserState with _$ShareWithUserState {
  const factory ShareWithUserState({
    @Default(null) UserProfilePB? currentUser,
    @Default([]) List<SharedUser> users,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default('') String shareLink,
    ShareRole? generalAccessRole,
    @Default(false) bool linkCopied,
    @Default(null) FlowyResult<void, FlowyError>? initialResult,
    @Default(null) FlowyResult<void, FlowyError>? shareResult,
    @Default(null) FlowyResult<void, FlowyError>? removeResult,
    @Default(null) FlowyResult<void, FlowyError>? updateRoleResult,
  }) = _ShareWithUserState;

  factory ShareWithUserState.initial() => const ShareWithUserState();
}
