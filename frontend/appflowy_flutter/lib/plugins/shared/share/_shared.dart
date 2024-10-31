import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/plugins/shared/share/share_menu.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareMenuButton extends StatelessWidget {
  const ShareMenuButton({
    super.key,
    required this.tabs,
  });

  final List<ShareMenuTab> tabs;

  @override
  Widget build(BuildContext context) {
    final shareBloc = context.read<ShareBloc>();
    final databaseBloc = context.read<DatabaseTabBarBloc?>();
    final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    return SizedBox(
      height: 32.0,
      child: IntrinsicWidth(
        child: AppFlowyPopover(
          direction: PopoverDirection.bottomWithRightAligned,
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          offset: const Offset(0, 8),
          onOpen: () {
            context
                .read<ShareBloc>()
                .add(const ShareEvent.updatePublishStatus());
          },
          popupBuilder: (context) => MultiBlocProvider(
            providers: [
              if (databaseBloc != null)
                BlocProvider.value(
                  value: databaseBloc,
                ),
              BlocProvider.value(value: shareBloc),
              BlocProvider.value(value: userWorkspaceBloc),
            ],
            child: ShareMenu(
              tabs: tabs,
            ),
          ),
          child: PrimaryRoundedButton(
            text: LocaleKeys.shareAction_buttonText.tr(),
            figmaLineHeight: 16,
          ),
        ),
      ),
    );
  }
}
