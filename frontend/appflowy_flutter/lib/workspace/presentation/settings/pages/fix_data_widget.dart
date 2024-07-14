import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FixDataWidget extends StatelessWidget {
  const FixDataWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCategory(
      title: LocaleKeys.settings_manageDataPage_data_fixYourData.tr(),
      children: [
        SingleSettingAction(
          labelMaxLines: 4,
          label: LocaleKeys.settings_manageDataPage_data_fixYourDataDescription
              .tr(),
          buttonLabel: LocaleKeys.settings_manageDataPage_data_fixButton.tr(),
          onPressed: () {
            FixDataManager.checkWorkspaceHealth(dryRun: true);
          },
        ),
      ],
    );
  }
}

class FixDataManager {
  static Future<void> checkWorkspaceHealth({
    required bool dryRun,
  }) async {
    try {
      final currentWorkspace =
          await UserBackendService.getCurrentWorkspace().getOrThrow();
      // get all the views in the workspace
      final result = await ViewBackendService.getAllViews().getOrThrow();
      final allViews = result.items;

      // dump all the views in the workspace
      dumpViews('all views', allViews);

      // get the workspace
      final workspaces = allViews.where(
        (e) => e.parentViewId == '' && e.id == currentWorkspace.id,
      );
      dumpViews('workspaces', workspaces.toList());

      if (workspaces.length != 1) {
        Log.error('Failed to fix workspace: workspace not found');
        // there should be only one workspace
        return;
      }

      final workspace = workspaces.first;

      // check the health of the spaces
      await checkSpaceHealth(workspace: workspace, allViews: allViews);

      // add other checks here
      // ...
    } catch (e) {
      Log.error('Failed to fix space relation: $e');
    }
  }

  static Future<void> checkSpaceHealth({
    required ViewPB workspace,
    required List<ViewPB> allViews,
    bool dryRun = true,
  }) async {
    try {
      final workspaceChildViews =
          await ViewBackendService.getChildViews(viewId: workspace.id)
              .getOrThrow();
      final workspaceChildViewIds =
          workspaceChildViews.map((e) => e.id).toSet();
      final spaces = allViews.where((e) => e.isSpace).toList();

      //
      for (final space in spaces) {
        // the space is the top level view, so its parent view id should be the workspace id
        // and the workspace should have the space in its child views
        if (space.parentViewId != workspace.id ||
            !workspaceChildViewIds.contains(space.id)) {
          Log.info('found an issue: space is not in the workspace: $space');
          if (!dryRun) {
            // move the space to the workspace if it is not in the workspace
            await ViewBackendService.moveViewV2(
              viewId: space.id,
              newParentId: workspace.id,
              prevViewId: null,
            );
          }
          workspaceChildViewIds.add(space.id);
        }
      }
    } catch (e) {
      Log.error('Failed to check space health: $e');
    }
  }

  static void dumpViews(String prefix, List<ViewPB> views) {
    for (int i = 0; i < views.length; i++) {
      final view = views[i];
      Log.info('$prefix $i: $view)');
    }
  }
}
