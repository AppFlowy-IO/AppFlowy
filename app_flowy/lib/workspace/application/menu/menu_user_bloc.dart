import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'menu_user_bloc.freezed.dart';

class MenuUserBloc extends Bloc<MenuUserEvent, MenuUserState> {
  final IUser iUserImpl;

  MenuUserBloc(this.iUserImpl) : super(MenuUserState.initial(iUserImpl.user));

  @override
  Stream<MenuUserState> mapEventToState(MenuUserEvent event) async* {
    yield* event.map(
      initial: (_) async* {
        // fetch workspaces
        iUserImpl.fetchWorkspaces().then((result) {
          result.fold(
            (workspaces) async* {
              yield state.copyWith(workspaces: some(workspaces));
            },
            (error) async* {
              yield state.copyWith(successOrFailure: right(error.msg));
            },
          );
        });
      },
      fetchWorkspaces: (_FetchWorkspaces value) async* {},
    );
  }

  @override
  Future<void> close() async {
    super.close();
  }
}

@freezed
class MenuUserEvent with _$MenuUserEvent {
  const factory MenuUserEvent.initial() = _Initial;
  const factory MenuUserEvent.fetchWorkspaces() = _FetchWorkspaces;
}

@freezed
class MenuUserState with _$MenuUserState {
  const factory MenuUserState({
    required UserDetail user,
    required Option<List<Workspace>> workspaces,
    required Either<Unit, String> successOrFailure,
  }) = _MenuUserState;

  factory MenuUserState.initial(UserDetail user) => MenuUserState(
        user: user,
        workspaces: none(),
        successOrFailure: left(unit),
      );
}
