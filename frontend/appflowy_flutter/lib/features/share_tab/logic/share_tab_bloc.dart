import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/data/repositories/share_with_user_repository.dart';
import 'package:appflowy/features/share_tab/logic/share_tab_event.dart';
import 'package:appflowy/features/share_tab/logic/share_tab_state.dart';
import 'package:appflowy/features/util/extensions.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';

export 'share_tab_event.dart';
export 'share_tab_state.dart';

class ShareTabBloc extends Bloc<ShareTabEvent, ShareTabState> {
  ShareTabBloc({
    required this.repository,
    required this.pageId,
    required this.workspaceId,
  }) : super(ShareTabState.initial()) {
    on<ShareTabEventInitialize>(_onInitial);
    on<ShareTabEventLoadSharedUsers>(_onGetSharedUsers);
    on<ShareTabEventInviteUsers>(_onShare);
    on<ShareTabEventRemoveUsers>(_onRemove);
    on<ShareTabEventUpdateUserAccessLevel>(_onUpdateAccessLevel);
    on<ShareTabEventUpdateGeneralAccessLevel>(_onUpdateGeneralAccess);
    on<ShareTabEventCopyShareLink>(_onCopyLink);
    on<ShareTabEventSearchAvailableUsers>(_onSearchAvailableUsers);
    on<ShareTabEventConvertToMember>(_onTurnIntoMember);
    on<ShareTabEventClearState>(_onClearState);
    on<ShareTabEventUpdateSharedUsers>(_onUpdateSharedUsers);
    on<ShareTabEventUpgradeToProClicked>(_onUpgradeToProClicked);
  }

  final ShareWithUserRepository repository;
  final String workspaceId;
  final String pageId;

  // Used to listen for shared view updates.
  FolderNotificationListener? _folderNotificationListener;

  @override
  Future<void> close() async {
    await _folderNotificationListener?.stop();
    await super.close();
  }

  Future<void> _onInitial(
    ShareTabEventInitialize event,
    Emitter<ShareTabState> emit,
  ) async {
    if (!FeatureFlag.sharedSection.isOn) {
      emit(
        state.copyWith(
          errorMessage: 'Sharing is currently disabled.',
          users: [],
          isLoading: false,
        ),
      );
      return;
    }

    _initFolderNotificationListener();

    final result = await repository.getCurrentUserProfile();
    final currentUser = result.fold(
      (user) => user,
      (error) => null,
    );

    final sectionTypeResult = await repository.getCurrentPageSectionType(
      pageId: pageId,
    );
    final sectionType = sectionTypeResult.fold(
      (type) => type,
      (error) => SharedSectionType.unknown,
    );

    final shareLink = ShareConstants.buildShareUrl(
      workspaceId: workspaceId,
      viewId: pageId,
    );

    final users = await _getSharedUsers();

    final hasClickedUpgradeToPro =
        await repository.getUpgradeToProButtonClicked(
      workspaceId: workspaceId,
    );

    emit(
      state.copyWith(
        currentUser: currentUser,
        shareLink: shareLink,
        users: users,
        sectionType: sectionType,
        hasClickedUpgradeToPro: hasClickedUpgradeToPro,
      ),
    );
  }

  Future<void> _onGetSharedUsers(
    ShareTabEventLoadSharedUsers event,
    Emitter<ShareTabState> emit,
  ) async {
    if (!FeatureFlag.sharedSection.isOn) {
      return;
    }

    emit(
      state.copyWith(
        errorMessage: '',
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
    ShareTabEventInviteUsers event,
    Emitter<ShareTabState> emit,
  ) async {
    emit(
      state.copyWith(
        errorMessage: '',
      ),
    );

    final result = await repository.sharePageWithUser(
      pageId: pageId,
      accessLevel: event.accessLevel,
      emails: event.emails,
    );

    await result.fold(
      (_) async {
        final users = await _getSharedUsers();

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
    ShareTabEventRemoveUsers event,
    Emitter<ShareTabState> emit,
  ) async {
    emit(
      state.copyWith(
        errorMessage: '',
      ),
    );

    final result = await repository.removeSharedUserFromPage(
      pageId: pageId,
      emails: event.emails,
    );

    await result.fold(
      (_) async {
        final users = await _getSharedUsers();
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
    ShareTabEventUpdateUserAccessLevel event,
    Emitter<ShareTabState> emit,
  ) async {
    emit(
      state.copyWith(),
    );

    final result = await repository.sharePageWithUser(
      pageId: pageId,
      accessLevel: event.accessLevel,
      emails: [event.email],
    );

    await result.fold(
      (_) async {
        final users = await _getSharedUsers();
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
    ShareTabEventUpdateGeneralAccessLevel event,
    Emitter<ShareTabState> emit,
  ) {
    emit(
      state.copyWith(
        generalAccessRole: event.accessLevel,
      ),
    );
  }

  void _onCopyLink(
    ShareTabEventCopyShareLink event,
    Emitter<ShareTabState> emit,
  ) {
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
    ShareTabEventSearchAvailableUsers event,
    Emitter<ShareTabState> emit,
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
    ShareTabEventConvertToMember event,
    Emitter<ShareTabState> emit,
  ) async {
    emit(
      state.copyWith(
        errorMessage: '',
      ),
    );

    final result = await repository.changeRole(
      workspaceId: workspaceId,
      email: event.email,
      role: ShareRole.member,
    );

    await result.fold(
      (_) async {
        final users = await _getSharedUsers();
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

  Future<SharedUsers> _getSharedUsers() async {
    final shareResult = await repository.getSharedUsersInPage(
      pageId: pageId,
    );
    return shareResult.fold(
      (users) => users,
      (error) => state.users,
    );
  }

  void _onClearState(
    ShareTabEventClearState event,
    Emitter<ShareTabState> emit,
  ) {
    emit(
      state.copyWith(
        errorMessage: '',
      ),
    );
  }

  void _onUpdateSharedUsers(
    ShareTabEventUpdateSharedUsers event,
    Emitter<ShareTabState> emit,
  ) {
    emit(
      state.copyWith(
        users: event.users,
      ),
    );
  }

  Future<void> _onUpgradeToProClicked(
    ShareTabEventUpgradeToProClicked event,
    Emitter<ShareTabState> emit,
  ) async {
    await repository.setUpgradeToProButtonClicked(
      workspaceId: workspaceId,
    );
    emit(
      state.copyWith(
        hasClickedUpgradeToPro: true,
      ),
    );
  }

  void _initFolderNotificationListener() {
    _folderNotificationListener = FolderNotificationListener(
      objectId: pageId,
      handler: (notification, result) {
        if (notification == FolderNotification.DidUpdateSharedUsers) {
          final response = result.fold(
            (payload) {
              final repeatedSharedUsers =
                  RepeatedSharedUserPB.fromBuffer(payload);
              return repeatedSharedUsers;
            },
            (error) => null,
          );
          Log.debug('update shared users: $response');
          if (response != null) {
            add(
              ShareTabEvent.updateSharedUsers(
                users: response.sharedUsers.reversed.toList(),
              ),
            );
          }
        }
      },
    );
  }
}
