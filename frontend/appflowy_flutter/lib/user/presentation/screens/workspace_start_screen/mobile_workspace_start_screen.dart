import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// TODO: needs refactor when multiple workspaces are supported
class MobileWorkspaceStartScreen extends StatefulWidget {
  const MobileWorkspaceStartScreen({
    super.key,
    required this.workspaceState,
  });

  @override
  State<MobileWorkspaceStartScreen> createState() =>
      _MobileWorkspaceStartScreenState();
  final WorkspaceState workspaceState;
}

class _MobileWorkspaceStartScreenState
    extends State<MobileWorkspaceStartScreen> {
  WorkspacePB? selectedWorkspace;
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    final size = MediaQuery.of(context).size;
    const double spacing = 16.0;
    final List<DropdownMenuEntry<WorkspacePB>> workspaceEntries =
        <DropdownMenuEntry<WorkspacePB>>[];
    for (final WorkspacePB workspace in widget.workspaceState.workspaces) {
      workspaceEntries.add(
        DropdownMenuEntry<WorkspacePB>(
          value: workspace,
          label: workspace.name,
        ),
      );
    }

// render the workspace dropdown menu if success, otherwise render error page
    final body = widget.workspaceState.successOrFailure.fold(
      (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(50, 0, 50, 30),
          child: Column(
            children: [
              const Spacer(),
              const FlowySvg(
                FlowySvgs.flowy_logo_xl,
                size: Size.square(64),
                blendMode: null,
              ),
              const VSpace(spacing * 2),
              Text(
                LocaleKeys.workspace_chooseWorkspace.tr(),
                style: style.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const VSpace(spacing * 4),
              DropdownMenu<WorkspacePB>(
                width: size.width - 100,
                // TODO: The following code cause the bad state error, need to fix it
                // initialSelection: widget.workspaceState.workspaces.first,
                label: const Text('Workspace'),
                controller: controller,
                dropdownMenuEntries: workspaceEntries,
                onSelected: (WorkspacePB? workspace) {
                  setState(() {
                    selectedWorkspace = workspace;
                  });
                },
              ),
              const Spacer(),
              // TODO: needs to implement create workspace in the future
              // TextButton(
              //   child: Text(
              //     LocaleKeys.workspace_create.tr(),
              //     style: style.textTheme.labelMedium,
              //     textAlign: TextAlign.center,
              //   ),
              //   onPressed: () {
              //     setState(() {
              //          // same method as in desktop
              // context.read<WorkspaceBloc>().add(
              //       WorkspaceEvent.createWorkspace(
              //         LocaleKeys.workspace_hint.tr(),
              //         "",
              //       ),
              //     );
              //     });
              //   },
              // ),
              const VSpace(spacing / 2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: () {
                  if (selectedWorkspace == null) {
                    // If user didn't choose any workspace, pop to the initial workspace(first workspace)
                    _popToWorkspace(
                      context,
                      widget.workspaceState.workspaces.first,
                    );
                    return;
                  }
                  // pop to the selected workspace
                  _popToWorkspace(
                    context,
                    selectedWorkspace!,
                  );
                },
                child: Text(LocaleKeys.signUp_getStartedText.tr()),
              ),
              const VSpace(spacing),
            ],
          ),
        );
      },
      (error) {
        return Center(
          child: AppFlowyErrorPage(
            error: error,
          ),
        );
      },
    );

    return Scaffold(
      body: body,
    );
  }
}

// same method as in desktop
void _popToWorkspace(BuildContext context, WorkspacePB workspace) {
  context.pop(workspace.id);
}
