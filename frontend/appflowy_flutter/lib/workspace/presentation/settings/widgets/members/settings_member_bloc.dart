import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_member_bloc.freezed.dart';

class WorkspaceMemberBloc
    extends Bloc<WorkspaceMemberEvent, WorkspaceMemberState> {
  WorkspaceMemberBloc({
    required this.userProfile,
  }) : super(WorkspaceMemberState.initial()) {
    on<WorkspaceMemberEvent>((event, emit) {
      event.map(
        getWorkspaceMembers: (_) {},
        addWorkspaceMember: (e) {},
        removeWorkspaceMember: (e) {},
        updateWorkspaceMember: (e) {},
      );
    });
  }

  final UserProfilePB userProfile;

  Future<void> _getWorkspaceMembers(Emitter emit) async {
    // final result = await UserEventGetWorkspaceMember().send();
    // result.fold((s) => emit(state.copyWith(
    //   members: s.
    // )), (e) => null)
  }
}

@freezed
class WorkspaceMemberEvent with _$WorkspaceMemberEvent {
  const factory WorkspaceMemberEvent.getWorkspaceMembers(String path) =
      GetWorkspaceMembers;
  const factory WorkspaceMemberEvent.addWorkspaceMember(String email) =
      AddWorkspaceMember;
  const factory WorkspaceMemberEvent.removeWorkspaceMember(String email) =
      RemoveWorkspaceMember;
  const factory WorkspaceMemberEvent.updateWorkspaceMember(AFRolePB role) =
      UpdateWorkspaceMember;
}

@freezed
class WorkspaceMemberState with _$WorkspaceMemberState {
  const factory WorkspaceMemberState({
    @Default([]) List<WorkspaceMemberPB> members,
    @Default(AFRolePB.Guest) AFRolePB myRole,
  }) = _WorkspaceMemberState;

  factory WorkspaceMemberState.initial() => const WorkspaceMemberState();
}
