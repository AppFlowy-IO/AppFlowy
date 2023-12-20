import 'package:appflowy/workspace/presentation/settings/settings_members_view.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'members_settings_bloc.freezed.dart';

class MockMembersService {
  static Future<Either<Error, List<MockMember>>> getMembers(
    String workspaceId,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    return right(mockedMembers);
  }

  static Future<Either<Error, String>> getInviteLink(
    String workspaceId,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    return right(
      'https://www.appflowy.io/invite/c5faf41cf1bb4960a49994c6f2b0a6bd36c7c4e5',
    );
  }
}

class MembersSettingsBloc
    extends Bloc<MembersSettingsEvent, MembersSettingsState> {
  MembersSettingsBloc() : super(const _Initial()) {
    on<MembersSettingsEvent>((event, emit) async {
      await event.when(
        started: () async {
          final dataOrFailures = await Future.wait([
            // Get Members,
            MockMembersService.getMembers('workspaceId'),
            // Get Invite link
            MockMembersService.getInviteLink('workspaceId'),
          ]);

          if (dataOrFailures.any((e) => e.isLeft())) {
            emit(const MembersSettingsState.failure());
          }

          final List<MockMember> members = dataOrFailures.first
              .fold((l) => null, (r) => r as List<MockMember>)!;
          final String link =
              dataOrFailures.last.fold((l) => null, (r) => r as String)!;

          emit(
            MembersSettingsState.data(
              data: MembersSettingsData(
                members: members,
                inviteLink: link,
              ),
            ),
          );
        },
        changeRole: (name, role) {},
        invite: (email) {},
        removeMember: (name) {},
      );
    });
  }
}

@freezed
class MembersSettingsEvent with _$MembersSettingsEvent {
  const factory MembersSettingsEvent.started() = _Started;
  const factory MembersSettingsEvent.changeRole({
    required String name,
    required String role,
  }) = _ChangeRole;
  const factory MembersSettingsEvent.invite({
    required String email,
  }) = _InviteEmail;
  const factory MembersSettingsEvent.removeMember({
    required String name,
  }) = _RemoveMember;
}

@freezed
class MembersSettingsState with _$MembersSettingsState {
  const factory MembersSettingsState.initial() = _Initial;
  const factory MembersSettingsState.loading() = _Loading;
  const factory MembersSettingsState.failure() = _Failure;
  const factory MembersSettingsState.data({
    required MembersSettingsData data,
  }) = _Data;
}

@freezed
class MembersSettingsData with _$MembersSettingsData {
  const factory MembersSettingsData({
    required List<MockMember> members,
    required String inviteLink,
  }) = _MembersSettingsData;
}
