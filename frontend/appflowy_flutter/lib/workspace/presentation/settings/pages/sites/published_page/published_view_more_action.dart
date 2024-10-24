import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class PublishedViewMoreAction extends StatelessWidget {
  const PublishedViewMoreAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: SettingsPageSitesConstants.threeDotsButtonWidth,
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowySvg(FlowySvgs.three_dots_s),
      ),
    );
  }
}
