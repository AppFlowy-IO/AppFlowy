import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/rename_view_dialog.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarNewPageButton extends StatelessWidget {
  const SidebarNewPageButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: HomeSizes.newPageSectionHeight,
      child: FlowyButton(
        onTap: () async => _createNewPage(context),
        leftIcon: const FlowySvg(
          FlowySvgs.new_app_m,
          blendMode: null,
        ),
        leftIconSize: const Size.square(24.0),
        margin: const EdgeInsets.only(left: 4.0),
        iconPadding: 8.0,
        text: FlowyText.regular(
          LocaleKeys.newPageText.tr(),
          lineHeight: 1.15,
        ),
      ),
    );
  }

  Future<void> _createNewPage(BuildContext context) async {
    return createViewAndShowRenameDialogIfNeeded(
      context,
      LocaleKeys.newPageText.tr(),
      (viewName, _) {
        if (viewName.isNotEmpty) {
          // if the workspace is collaborative, create the view in the private section by default.
          final section =
              context.read<UserWorkspaceBloc>().state.isCollabWorkspaceOn
                  ? ViewSectionPB.Private
                  : ViewSectionPB.Public;
          final spaceState = context.read<SpaceBloc>().state;
          if (spaceState.spaces.isNotEmpty) {
            context.read<SpaceBloc>().add(
                  SpaceEvent.createPage(
                    name: viewName,
                    viewSection: section,
                    index: 0,
                  ),
                );
          } else {
            context.read<SidebarSectionsBloc>().add(
                  SidebarSectionsEvent.createRootViewInSection(
                    name: viewName,
                    viewSection: section,
                    index: 0,
                  ),
                );
          }
        }
      },
    );
  }
}
