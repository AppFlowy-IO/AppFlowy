import 'package:appflowy/features/share/data/models/share_role.dart';
import 'package:appflowy/features/share/data/models/shared_user.dart';
import 'package:appflowy/features/share/data/repositories/share_repository.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_with_user_bloc.freezed.dart';

class ShareWithUserBloc extends Bloc<ShareWithUserEvent, ShareWithUserState> {
  ShareWithUserBloc({
    required this.repository,
    required this.pageId,
    required this.shareLink,
  }) : super(ShareWithUserState.initial()) {
    on<LoadSharedUsers>(_onLoad);
    on<InviteUser>(_onInvite);
    on<RemoveUser>(_onRemove);
    on<UpdateUserRole>(_onUpdateRole);
    on<UpdateGeneralAccess>(_onUpdateGeneralAccess);
    on<CopyLink>(_onCopyLink);
  }

  final ShareRepository repository;
  final String pageId;
  final String shareLink;

  Future<void> _onLoad(
    LoadSharedUsers event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    final result = await repository.getUsersInSharedPage(
      pageId: event.pageId,
    );
    result.fold(
      (users) => emit(
        state.copyWith(
          users: users,
          isLoading: false,
        ),
      ),
      (error) => emit(
        state.copyWith(errorMessage: error.msg, isLoading: false),
      ),
    );
  }

  Future<void> _onInvite(
    InviteUser event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    final result = await repository.sharePageWithUser(
      pageId: event.pageId,
      role: event.role,
      emails: event.emails,
    );
    result.fold(
      (_) => add(
        ShareWithUserEvent.load(
          pageId: event.pageId,
        ),
      ),
      (error) => emit(
        state.copyWith(errorMessage: error.msg),
      ),
    );
  }

  Future<void> _onRemove(
    RemoveUser event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    final result = await repository.removeUserFromPage(
      pageId: event.pageId,
      emails: event.emails,
    );
    result.fold(
      (_) => add(
        ShareWithUserEvent.load(
          pageId: event.pageId,
        ),
      ),
      (error) => emit(
        state.copyWith(
          errorMessage: error.msg,
          isLoading: false,
        ),
      ),
    );
  }

  Future<void> _onUpdateRole(
    UpdateUserRole event,
    Emitter<ShareWithUserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    final result = await repository.sharePageWithUser(
      pageId: event.pageId,
      role: event.role,
      emails: [event.email],
    );
    result.fold(
      (_) => add(
        ShareWithUserEvent.load(
          pageId: event.pageId,
        ),
      ),
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
    emit(state.copyWith(generalAccessRole: event.role));
  }

  void _onCopyLink(CopyLink event, Emitter<ShareWithUserState> emit) {
    getIt<ClipboardService>().setData(
      ClipboardServiceData(
        plainText: event.link,
      ),
    );

    emit(state.copyWith(linkCopied: true));
  }
}

@freezed
class ShareWithUserEvent with _$ShareWithUserEvent {
  /// Loads the shared users for the page.
  const factory ShareWithUserEvent.load({
    required String pageId,
  }) = LoadSharedUsers;

  /// Invites the users to the page.
  const factory ShareWithUserEvent.share({
    required String pageId,
    required List<String> emails,
    required ShareRole role,
  }) = ShareWithUser;

  /// Removes the users from the page.
  const factory ShareWithUserEvent.remove({
    required String pageId,
    required List<String> emails,
  }) = RemoveUser;

  /// Updates the role of the user.
  const factory ShareWithUserEvent.updateRole({
    required String pageId,
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
