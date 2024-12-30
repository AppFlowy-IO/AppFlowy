import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class DomainHeader extends StatelessWidget {
  const DomainHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...SettingsPageSitesConstants.namespaceHeaderTitles.map(
          (title) => Expanded(
            child: FlowyText.medium(
              title,
              fontSize: 14.0,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        // it used to align the three dots button in the published page item
        const HSpace(SettingsPageSitesConstants.threeDotsButtonWidth),
      ],
    );
  }
}
