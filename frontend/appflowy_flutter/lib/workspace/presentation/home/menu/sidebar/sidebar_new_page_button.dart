import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/rename_view_dialog.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarNewPageButton extends StatelessWidget {
  const SidebarNewPageButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final child = FlowyTextButton(
      LocaleKeys.newPageText.tr(),
      fillColor: Colors.transparent,
      hoverColor: Colors.transparent,
      fontColor: Theme.of(context).colorScheme.tertiary,
      onPressed: () async => createViewAndShowRenameDialogIfNeeded(
        context,
        LocaleKeys.newPageText.tr(),
        (viewName, _) {
          if (viewName.isNotEmpty) {
            // if the workspace is collaborative, create the view in the private section by default.
            final section =
                context.read<UserWorkspaceBloc>().state.isCollabWorkspaceOn
                    ? ViewSectionPB.Private
                    : ViewSectionPB.Public;
            context.read<SidebarSectionsBloc>().add(
                  SidebarSectionsEvent.createRootViewInSection(
                    name: viewName,
                    viewSection: section,
                  ),
                );
          }
        },
      ),
      heading: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: FlowySvg(
          FlowySvgs.new_app_s,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      padding: const EdgeInsets.all(0),
    );

    return SizedBox(
      height: 60,
      child: TopBorder(
        color: Theme.of(context).dividerColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: child,
        ),
      ),
    );
  }
}
