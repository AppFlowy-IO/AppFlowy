import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/workspace/welcome_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class WelcomeScreen extends StatelessWidget {
  final UserProfilePB userProfile;
  const WelcomeScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WelcomeBloc>(param1: userProfile)
        ..add(const WelcomeEvent.initial()),
      child: BlocBuilder<WelcomeBloc, WelcomeState>(
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

  Widget _renderBody(WelcomeState state) {
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
        LocaleKeys.workspace_create.tr(),
        fontSize: 14,
        hoverColor: CustomColors.of(context).lightGreyHover,
        onPressed: () {
          context.read<WelcomeBloc>().add(
              WelcomeEvent.createWorkspace(LocaleKeys.workspace_hint.tr(), ""));
        },
      ),
    );
  }

  Widget _renderList(List<WorkspacePB> workspaces) {
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

  void _handleOnPress(BuildContext context, WorkspacePB workspace) {
    context.read<WelcomeBloc>().add(WelcomeEvent.openWorkspace(workspace));

    Navigator.of(context).pop(workspace.id);
  }
}

class WorkspaceItem extends StatelessWidget {
  final WorkspacePB workspace;
  final void Function(WorkspacePB workspace) onPressed;
  const WorkspaceItem(
      {Key? key, required this.workspace, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FlowyTextButton(
        workspace.name,
        hoverColor: CustomColors.of(context).lightGreyHover,
        fontSize: 14,
        onPressed: () => onPressed(workspace),
      ),
    );
  }
}
