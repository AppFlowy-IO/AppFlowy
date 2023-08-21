import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/workspace_error_bloc.dart';

class WorkspaceErrorScreen extends StatelessWidget {
  final FlowyError error;
  final UserFolderPB userFolder;
  const WorkspaceErrorScreen({
    required this.userFolder,
    required this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: BlocProvider(
        create: (context) => WorkspaceErrorBloc(
          userFolder: userFolder,
          error: error,
        )..add(const WorkspaceErrorEvent.init()),
        child: BlocListener<WorkspaceErrorBloc, WorkspaceErrorState>(
          listenWhen: (previous, current) =>
              previous.workspaceState != current.workspaceState,
          listener: (context, state) async {
            await state.workspaceState.when(
              initial: () {},
              logout: () async {
                await getIt<AuthService>().signOut();
                await runAppFlowy();
              },
              reset: () async {
                await getIt<AuthService>().signOut();
                await runAppFlowy();
              },
              restoreFromSnapshot: () {},
              createNewWorkspace: () {},
            );
          },
          child: BlocBuilder<WorkspaceErrorBloc, WorkspaceErrorState>(
            builder: (context, state) {
              final List<Widget> children = [
                WorkspaceErrorDescription(error: error),
              ];

              // if (state.snapshots.isNotEmpty) {
              //   children.add(
              //     ConstrainedBox(
              //       constraints: const BoxConstraints(
              //         maxHeight: 200,
              //         maxWidth: 200,
              //       ),
              //       child: const WorkspaceSnapshotList(),
              //     ),
              //   );
              // }

              children.addAll([
                const VSpace(50),
                const LogoutButton(),
                const VSpace(20),
                const ResetWorkspaceButton(),
              ]);

              return Center(
                child: SizedBox(
                  width: 500,
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: children,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class WorkspaceErrorDescription extends StatelessWidget {
  final FlowyError error;
  const WorkspaceErrorDescription({
    required this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceErrorBloc, WorkspaceErrorState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowyText.medium(
              state.initialError.msg.toString(),
              fontSize: 14,
              maxLines: 10,
            ),
            FlowyText.medium(
              "Error code: ${state.initialError.code.value.toString()}",
              fontSize: 12,
              maxLines: 1,
            )
          ],
        );
      },
    );
  }
}

class WorkspaceSnapshotList extends StatelessWidget {
  const WorkspaceSnapshotList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceErrorBloc, WorkspaceErrorState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.snapshots.length,
          itemBuilder: (context, index) {
            final snapshot = state.snapshots[index];

            final outputFormat = DateFormat('MM/dd/yyyy hh:mm a');
            final date = DateTime.fromMillisecondsSinceEpoch(
              snapshot.createdAt.toInt() * 1000,
            );

            return ListTile(
              title: Text(snapshot.snapshotDesc),
              subtitle: Text(outputFormat.format(date)),
              onTap: () {},
            );
          },
        );
      },
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 200,
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText.medium(
          LocaleKeys.settings_menu_logout.tr(),
          textAlign: TextAlign.center,
        ),
        onTap: () async {
          context.read<WorkspaceErrorBloc>().add(
                const WorkspaceErrorEvent.logout(),
              );
        },
      ),
    );
  }
}

class ResetWorkspaceButton extends StatelessWidget {
  const ResetWorkspaceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 200,
      child: FlowyButton(
        text: FlowyText.medium(
          LocaleKeys.workspace_reset.tr(),
          textAlign: TextAlign.center,
        ),
        onTap: () {
          context.read<WorkspaceErrorBloc>().add(
                const WorkspaceErrorEvent.resetWorkspace(),
              );
        },
      ),
    );
  }
}
