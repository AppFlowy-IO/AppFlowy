import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/settings/pages/fix_data_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SpaceOptimization extends StatelessWidget {
  const SpaceOptimization({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpaceHintButton(
      collapsedTitle: LocaleKeys.space_optimizeYourSpace.tr(),
      expandedTitle: LocaleKeys.space_optimizeYourSpace.tr(),
      expandedDescription: LocaleKeys.space_optimizeYourSpaceDescription.tr(),
      expandedButtonLabel: LocaleKeys.space_optimize.tr(),
      onClick: () async {
        // case 1.
        // check if there're any pages were assigned to the wrong parent.
        // if so, reassigned them to the correct parent.
        await WorkspaceDataManager.checkViewHealth(dryRun: false);

        // case 2.
        // check if there're any pages were created at the root in version less than 0.6.0
        // if so, move them to the space.
        //
        // this case happens when the user upgraded to space version,
        //  and then they created a page in the version less than 0.6.0,
        //  so that page was not visible in the space.
        await WorkspaceDataManager.checkViewsOutOfSpace(dryRun: false);
      },
    );
  }
}
