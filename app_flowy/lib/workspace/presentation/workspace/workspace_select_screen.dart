import 'package:app_flowy/workspace/application/workspace/workspace_list_bloc.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text_button.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/workspace_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';

class WorkspaceSelectScreen extends StatelessWidget {
  final UserRepo repo;
  const WorkspaceSelectScreen({
    Key? key,
    required this.repo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WorkspaceListBloc(repo)..add(const WorkspaceListEvent.initial()),
      child: BlocBuilder<WorkspaceListBloc, WorkspaceListState>(
        builder: (context, state) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(60.0),
              child: Column(
                children: [
                  _renderBody(state),
                  _renderCreateButton(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _renderBody(WorkspaceListState state) {
    final body = state.successOrFailure.fold(
      (_) => _renderList(state.workspaces),
      (error) => FlowyErrorPage(error.toString()),
    );
    return body;
  }

  Widget _renderCreateButton(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 40,
      child: FlowyTextButton(
        "Create workspace",
        fontSize: 14,
        onPressed: () {
          context
              .read<WorkspaceListBloc>()
              .add(const WorkspaceListEvent.createWorkspace("workspace", ""));
        },
      ),
    );
  }

  Widget _renderList(List<Workspace> workspaces) {
    return Expanded(
      child: StyledListView(
        itemBuilder: (BuildContext context, int index) {
          final workspace = workspaces[index];
          return WorkspaceItem(
            workspace: workspace,
            onPressed: (workspace) => _handleOnPress(context, workspace),
          );
        },
        itemCount: workspaces.length,
      ),
    );
  }

  void _handleOnPress(BuildContext context, Workspace workspace) {
    context
        .read<WorkspaceListBloc>()
        .add(WorkspaceListEvent.openWorkspace(workspace));

    Navigator.of(context).pop(workspace.id);
  }
}

class WorkspaceItem extends StatelessWidget {
  final Workspace workspace;
  final void Function(Workspace workspace) onPressed;
  const WorkspaceItem(
      {Key? key, required this.workspace, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FlowyTextButton(
        workspace.name,
        fontSize: 14,
        onPressed: () => onPressed(workspace),
      ),
    );
  }
}


// Bloc and Provider

// *************Provider***************
// class WorkspaceListNotifier with ChangeNotifier {
//   UserRepo repo;
//   List<Workspace> workspaces = [];
//   WorkspaceListNotifier({
//     required this.repo,
//   }) {
//     fetch();
//   }

//   void fetch() {
//     repo.fetchWorkspaces().then((result) {
//       result.fold((workspaces) {
//         this.workspaces = workspaces;
//         notifyListeners();
//       }, (error) {
//         Log.error(error);
//       });
//     });
//   }
// }

// class WorkspaceSelectScreen extends StatelessWidget {
//   final UserProfile user;
//   const WorkspaceSelectScreen({
//     Key? key,
//     required this.user,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//         providers: [
//           ChangeNotifierProvider(
//             create: (_) => WorkspaceListNotifier(repo: UserRepo(user: user)),
//           )
//         ],
//         child: Consumer<WorkspaceListNotifier>(builder: (ctx, notifier, child) {
//           return StyledListView(
//             itemBuilder: (BuildContext context, int index) {
//               final workspace = notifier.workspaces[index];
//               return WorkspaceItem(workspace);
//             },
//             itemCount: notifier.workspaces.length,
//           );
//         }));
//   }
// }

// *************Bloc***************
//
// class WorkspaceListBloc extends Bloc<WorkspaceListEvent, WorkspaceListState> {
//   UserRepo repo;
//   WorkspaceListBloc(this.repo) : super(WorkspaceListState.initial());

//   @override
//   Stream<WorkspaceListState> mapEventToState(
//     WorkspaceListEvent event,
//   ) async* {
//     yield* event.map(
//       initial: (e) async* {
//         yield* _fetchWorkspaces();
//       },
//     );
//   }

//   Stream<WorkspaceListState> _fetchWorkspaces() async* {
//     final workspacesOrFailed = await repo.fetchWorkspaces();

//     yield workspacesOrFailed.fold(
//         (workspaces) => state.copyWith(
//             workspaces: workspaces, successOrFailure: left(unit)),
//         (error) => state.copyWith(successOrFailure: right(error)));
//   }
// }

// @freezed
// abstract class WorkspaceListEvent with _$WorkspaceListEvent {
//   const factory WorkspaceListEvent.initial() = Initial;
// }

// @freezed
// abstract class WorkspaceListState implements _$WorkspaceListState {
//   const factory WorkspaceListState({
//     required bool isLoading,
//     required List<Workspace> workspaces,
//     required Either<Unit, WorkspaceError> successOrFailure,
//   }) = _WorkspaceListState;

//   factory WorkspaceListState.initial() => WorkspaceListState(
//         isLoading: false,
//         workspaces: List.empty(),
//         successOrFailure: left(unit),
//       );
// }
//
// class WorkspaceSelectScreen extends StatelessWidget {
//   final UserProfile user;
//   const WorkspaceSelectScreen({
//     Key? key,
//     required this.user,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => WorkspaceListBloc(UserRepo(user: user))
//         ..add(const WorkspaceListEvent.initial()),
//       child: BlocBuilder<WorkspaceListBloc, WorkspaceListState>(
//         builder: (context, state) {
//           return state.successOrFailure.fold(
//             (_) => StyledListView(
//               itemBuilder: (BuildContext context, int index) {
//                 final workspace = state.workspaces[index];
//                 return WorkspaceItem(workspace);
//               },
//               itemCount: state.workspaces.length,
//             ),
//             (error) => Container(),
//           );
//         },
//       ),
//     );
//   }
// }
