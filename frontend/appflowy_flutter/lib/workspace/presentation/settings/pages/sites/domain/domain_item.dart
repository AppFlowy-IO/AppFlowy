import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/domain_more_action.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DomainItem extends StatelessWidget {
  const DomainItem({
    super.key,
    required this.namespace,
    required this.homepage,
  });

  final String namespace;
  final String homepage;

  @override
  Widget build(BuildContext context) {
    final namespaceUrl = ShareConstants.buildNamespaceUrl(
      nameSpace: namespace,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Domain
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FlowyText(
              namespaceUrl,
              fontSize: 14.0,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Published Name

        // Homepage
        Expanded(child: _buildHomepage(context)),

        DomainMoreAction(namespace: namespace),
      ],
    );
  }

  Widget _buildHomepage(BuildContext context) {
    final plan = context.read<SettingsSitesBloc>().state.subscriptionInfo?.plan;
    final isFreePlan = plan == null || plan == WorkspacePlanPB.FreePlan;

    if (isFreePlan) {
      return Container(
        alignment: Alignment.centerLeft,
        child: FlowyTooltip(
          message: 'Upgrade to Pro Plan to set a homepage',
          child: PrimaryRoundedButton(
            text: 'Upgrade ↗',
            fontSize: 12.0,
            figmaLineHeight: 12.0,
            radius: 8.0,
            margin: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 6.0,
            ),
            onTap: () {},
          ),
        ),
      );
    }

    return FlowyText(
      homepage,
      fontSize: 14.0,
      overflow: TextOverflow.ellipsis,
    );
  }
}
