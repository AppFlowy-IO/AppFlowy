import 'package:appflowy/features/share/logic/share_with_user_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/plugins/shared/share/share_menu.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareMenuButton extends StatefulWidget {
  const ShareMenuButton({
    super.key,
    required this.tabs,
  });

  final List<ShareMenuTab> tabs;

  @override
  State<ShareMenuButton> createState() => _ShareMenuButtonState();
}

class _ShareMenuButtonState extends State<ShareMenuButton> {
  final popoverController = AFPopoverController();

  @override
  void initState() {
    super.initState();

    popoverController.addListener(() {
      if (context.mounted && popoverController.isOpen) {
        context.read<ShareBloc>().add(const ShareEvent.updatePublishStatus());
      }
    });
  }

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shareBloc = context.read<ShareBloc>();
    final databaseBloc = context.read<DatabaseTabBarBloc?>();
    final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    final shareWithUserBloc = context.read<ShareWithUserBloc>();
    final pageId = shareBloc.state.viewId;
    final workspaceId = userWorkspaceBloc.state.currentWorkspace?.workspaceId;
    // final animationDuration = const Duration(milliseconds: 120);

    return BlocBuilder<ShareBloc, ShareState>(
      builder: (context, state) {
        return AFPopover(
          controller: popoverController,
          anchor: AFAnchorAuto(
            offset: const Offset(-176, 12),
          ),
          // Enable animation
          // effects: [
          //   FadeEffect(duration: animationDuration),
          //   ScaleEffect(
          //     duration: animationDuration,
          //     begin: Offset(0.95, 0.95),
          //     end: Offset(1, 1),
          //     alignment: Alignment.topRight,
          //   ),
          //   MoveEffect(
          //     duration: animationDuration,
          //     begin: Offset(20, -20),
          //     end: Offset(0, 0),
          //     curve: Curves.easeOutQuad,
          //   ),
          // ],
          popover: (_) {
            return ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 414,
              ),
              child: MultiBlocProvider(
                providers: [
                  if (databaseBloc != null)
                    BlocProvider.value(
                      value: databaseBloc,
                    ),
                  BlocProvider.value(value: shareBloc),
                  BlocProvider.value(value: userWorkspaceBloc),
                  BlocProvider.value(value: shareWithUserBloc),
                ],
                child: ShareMenu(
                  tabs: widget.tabs,
                  viewName: state.viewName,
                ),
              ),
            );
          },
          child: AFFilledTextButton.primary(
            text: LocaleKeys.shareAction_buttonText.tr(),
            onTap: () {
              popoverController.show();
            },
          ),
        );
      },
    );
  }
}
