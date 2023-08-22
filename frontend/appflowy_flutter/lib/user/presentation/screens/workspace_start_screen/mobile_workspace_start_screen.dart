import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/workspace_start_screen/util/pop_to_workspace.dart';
import 'package:appflowy/user/presentation/screens/workspace_start_screen/util/util.dart';
import 'package:appflowy/workspace/application/workspace/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';

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
    // set initial selection when user didn't select anything from dropdown menu
    selectedWorkspace ??= workspaceEntries.first.value;
    return Scaffold(
      body: Padding(
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
              initialSelection: workspaceEntries.first.value,
              label: const Text('Workspace'),
              dropdownMenuEntries: workspaceEntries,
              onSelected: (WorkspacePB? workspace) {
                setState(() {
                  selectedWorkspace = workspace;
                });
              },
            ),
            const Spacer(),
            TextButton(
              child: Text(
                LocaleKeys.workspace_create.tr(),
                style: style.textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              onPressed: () => createWorkspace(context),
            ),
            const VSpace(spacing / 2),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: () => popToWorkspace(
                context,
                selectedWorkspace!,
              ),
              child: Text(LocaleKeys.signUp_getStartedText.tr()),
            ),
            const VSpace(spacing),
          ],
        ),
      ),
    );
  }
}
