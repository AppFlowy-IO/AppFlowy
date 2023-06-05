import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/workspace/welcome_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

class WelcomeScreen extends StatelessWidget {
  final UserProfilePB userProfile;
  const WelcomeScreen({
    final Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final _) => getIt<WelcomeBloc>(param1: userProfile)
        ..add(const WelcomeEvent.initial()),
      child: BlocBuilder<WelcomeBloc, WelcomeState>(
        builder: (final context, final state) {
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

  Widget _renderBody(final WelcomeState state) {
    final body = state.successOrFailure.fold(
      (final _) => _renderList(state.workspaces),
      (final error) => FlowyErrorPage(error.toString()),
    );
    return body;
  }

  Widget _renderCreateButton(final BuildContext context) {
    return SizedBox(
      width: 200,
      height: 40,
      child: FlowyTextButton(
        LocaleKeys.workspace_create.tr(),
        fontSize: 14,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onPressed: () {
          context.read<WelcomeBloc>().add(
                WelcomeEvent.createWorkspace(
                  LocaleKeys.workspace_hint.tr(),
                  "",
                ),
              );
        },
      ),
    );
  }

  Widget _renderList(final List<WorkspacePB> workspaces) {
    return Expanded(
      child: StyledListView(
        itemBuilder: (final BuildContext context, final int index) {
          final workspace = workspaces[index];
          return WorkspaceItem(
            workspace: workspace,
            onPressed: (final workspace) => _handleOnPress(context, workspace),
          );
        },
        itemCount: workspaces.length,
      ),
    );
  }

  void _handleOnPress(final BuildContext context, final WorkspacePB workspace) {
    context.read<WelcomeBloc>().add(WelcomeEvent.openWorkspace(workspace));

    Navigator.of(context).pop(workspace.id);
  }
}

class WorkspaceItem extends StatelessWidget {
  final WorkspacePB workspace;
  final void Function(WorkspacePB workspace) onPressed;
  const WorkspaceItem({
    final Key? key,
    required this.workspace,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: 46,
      child: FlowyTextButton(
        workspace.name,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        fontSize: 14,
        onPressed: () => onPressed(workspace),
      ),
    );
  }
}
