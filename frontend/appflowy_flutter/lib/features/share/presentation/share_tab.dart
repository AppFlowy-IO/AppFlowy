import 'package:appflowy/features/share/logic/share_with_user_bloc.dart';
import 'package:appflowy/features/share/presentation/widgets/copy_link_widget.dart';
import 'package:appflowy/features/share/presentation/widgets/general_access_section.dart';
import 'package:appflowy/features/share/presentation/widgets/people_with_acess_section.dart';
import 'package:appflowy/features/share/presentation/widgets/share_with_user_widget.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareTab extends StatelessWidget {
  const ShareTab({
    super.key,
    required this.workspaceId,
    required this.pageId,
  });

  final String workspaceId;
  final String pageId;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // share page with user by email
        VSpace(theme.spacing.l),
        ShareWithUserWidget(),

        // shared users
        VSpace(theme.spacing.l),
        BlocBuilder<ShareWithUserBloc, ShareWithUserState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.errorMessage.isNotEmpty) {
              return Center(child: Text(state.errorMessage));
            }
            return PeopleWithAccessSection(
              currentUserEmail: state.currentUser?.email ?? '',
              users: state.users,
            );
          },
        ),

        // general access
        VSpace(theme.spacing.m),
        GeneralAccessSection(),

        // copy link
        VSpace(theme.spacing.l),
        const AFDivider(),
        VSpace(theme.spacing.xl),
        CopyLinkWidget(),
        VSpace(theme.spacing.m),
      ],
    );
  }
}
