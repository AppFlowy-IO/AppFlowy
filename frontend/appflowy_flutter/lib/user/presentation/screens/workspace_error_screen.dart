import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/workspace_error_bloc.dart';

class WorkspaceErrorScreen extends StatelessWidget {
  const WorkspaceErrorScreen({
    super.key,
    required this.userFolder,
    required this.error,
  });

  final UserFolderPB userFolder;
  final FlowyError error;

  static const routeName = "/WorkspaceErrorScreen";
  // arguments names to used in GoRouter
  static const argError = "error";
  static const argUserFolder = "userFolder";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: BlocProvider(
        create: (context) => WorkspaceErrorBloc(
          userFolder: userFolder,
          error: error,
        )..add(const WorkspaceErrorEvent.init()),
        child: MultiBlocListener(
          listeners: [
            BlocListener<WorkspaceErrorBloc, WorkspaceErrorState>(
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
            ),
            BlocListener<WorkspaceErrorBloc, WorkspaceErrorState>(
              listenWhen: (previous, current) =>
                  previous.loadingState != current.loadingState,
              listener: (context, state) async {
                state.loadingState?.when(
                  loading: () {},
                  finish: (error) {
                    error.fold(
                      (_) {},
                      (err) {
                        showSnapBar(context, err.msg);
                      },
                    );
                  },
                  idle: () {},
                );
              },
            ),
          ],
          child: BlocBuilder<WorkspaceErrorBloc, WorkspaceErrorState>(
            builder: (context, state) {
              final List<Widget> children = [
                WorkspaceErrorDescription(error: error),
              ];

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
  const WorkspaceErrorDescription({super.key, required this.error});

  final FlowyError error;

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
            ),
          ],
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
      width: 200,
      height: 40,
      child: BlocBuilder<WorkspaceErrorBloc, WorkspaceErrorState>(
        builder: (context, state) {
          final isLoading = state.loadingState?.isLoading() ?? false;
          final icon = isLoading
              ? const Center(
                  child: CircularProgressIndicator.adaptive(),
                )
              : null;

          return FlowyButton(
            text: FlowyText.medium(
              LocaleKeys.workspace_reset.tr(),
              textAlign: TextAlign.center,
            ),
            onTap: () {
              NavigatorAlertDialog(
                title: LocaleKeys.workspace_resetWorkspacePrompt.tr(),
                confirm: () {
                  context.read<WorkspaceErrorBloc>().add(
                        const WorkspaceErrorEvent.resetWorkspace(),
                      );
                },
              ).show(context);
            },
            rightIcon: icon,
          );
        },
      ),
    );
  }
}
