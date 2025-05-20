import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/access_level_list_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/edit_access_level_widget.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class SharedGroupWidget extends StatelessWidget {
  const SharedGroupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFMenuItem(
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
      ),
      leading: _buildLeading(context),
      title: _buildTitle(context),
      subtitle: _buildSubtitle(context),
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return AFAvatar(
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: FlowySvg(
          FlowySvgs.app_logo_s, // replace it with group avatar
          blendMode: null,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Row(
      children: [
        Text(
          LocaleKeys.shareTab_anyoneAtWorkspace
              .tr(), // replace it with group name
          style: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
          ),
        ),
        HSpace(theme.spacing.xs),
        FlowySvg(
          FlowySvgs.arrow_down_s,
          color: theme.textColorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      LocaleKeys.shareTab_anyoneInGroupWithLinkCanEdit
          .tr(), // replace it with group description
      textAlign: TextAlign.left,
      style: theme.textStyle.caption.standard(
        color: theme.textColorScheme.secondary,
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return EditAccessLevelWidget(
      disabled: true,
      selectedAccessLevel: ShareAccessLevel.fullAccess,
      callbacks: AccessLevelListCallbacks.none(),
    );
  }
}
