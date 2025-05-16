import 'package:appflowy/features/share/logic/share_with_user_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CopyLinkWidget extends StatelessWidget {
  const CopyLinkWidget({
    super.key,
    required this.shareLink,
  });

  final String shareLink;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: AFTextField(
            initialText: shareLink,
            size: AFTextFieldSize.m,
            readOnly: true,
          ),
        ),
        HSpace(theme.spacing.s),
        AFOutlinedIconTextButton.normal(
          text: 'Copy link',
          size: AFButtonSize.l,
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.l,
            vertical: theme.spacing.s,
          ),
          iconBuilder: (context, isHovering, disabled) => FlowySvg(
            FlowySvgs.toolbar_link_m,
          ),
          onTap: () {
            context.read<ShareWithUserBloc>().add(
                  ShareWithUserEvent.copyLink(link: shareLink),
                );

            showToastNotification(
              message: 'Copied link to clipboard',
            );
          },
        ),
      ],
    );
  }
}
