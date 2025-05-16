import 'package:appflowy/features/share/data/repositories/rust_share_repository.dart';
import 'package:appflowy/features/share/logic/share_with_user_bloc.dart';
import 'package:appflowy/features/share/presentation/widgets/share_with_user_widget.dart';
import 'package:appflowy/features/share/presentation/widgets/shared_users_widget.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
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
    final shareLink = ShareConstants.buildShareUrl(
      workspaceId: workspaceId,
      viewId: pageId,
    );

    return BlocProvider(
      create: (context) => ShareWithUserBloc(
        repository: RustShareRepository(),
        pageId: pageId,
        shareLink: shareLink,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          VSpace(theme.spacing.l),
          ShareWithUserWidget(),
          VSpace(theme.spacing.l),
          SharedUserList(),
        ],
      ),
    );
  }
}
