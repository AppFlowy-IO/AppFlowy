import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
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
            WorkspaceDataManager.checkWorkspaceHealth(dryRun: true);
          },
        ),
      ],
    );
  }
}

class WorkspaceDataManager {
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

      // check the health of the views
      await checkViewHealth(workspace: workspace, allViews: allViews);

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

  static Future<List<ViewPB>> checkViewHealth({
    ViewPB? workspace,
    List<ViewPB>? allViews,
    bool dryRun = true,
  }) async {
    // Views whose parent view does not have the view in its child views
    final List<ViewPB> unlistedChildViews = [];
    // Views whose parent is not in allViews
    final List<ViewPB> orphanViews = [];

    try {
      if (workspace == null || allViews == null) {
        final currentWorkspace =
            await UserBackendService.getCurrentWorkspace().getOrThrow();
        // get all the views in the workspace
        final result = await ViewBackendService.getAllViews().getOrThrow();
        allViews = result.items;
        workspace = allViews.firstWhereOrNull(
          (e) => e.id == currentWorkspace.id,
        );
      }

      for (final view in allViews) {
        if (view.parentViewId == '') {
          continue;
        }

        final parentView = allViews.firstWhereOrNull(
          (e) => e.id == view.parentViewId,
        );

        if (parentView == null) {
          orphanViews.add(view);
          continue;
        }

        final childViewsOfParent =
            await ViewBackendService.getChildViews(viewId: parentView.id)
                .getOrThrow();
        final result = childViewsOfParent.any((e) => e.id == view.id);
        if (!result) {
          unlistedChildViews.add(view);
        }
      }
    } catch (e) {
      Log.error('Failed to check space health: $e');
      return [];
    }

    for (final view in unlistedChildViews) {
      Log.info(
        '[workspace] found an issue: view is not in the parent view\'s child views, view: ${view.toProto3Json()}}',
      );
    }

    for (final view in orphanViews) {
      Log.debug('[workspace] orphanViews: ${view.toProto3Json()}');
    }

    if (!dryRun && unlistedChildViews.isNotEmpty) {
      Log.info(
        '[workspace] start to fix ${unlistedChildViews.length} unlistedChildViews ...',
      );
      for (final view in unlistedChildViews) {
        // move the view to the parent view if it is not in the parent view's child views
        Log.info(
          '[workspace] move view: $view to its parent view ${view.parentViewId}',
        );
        await ViewBackendService.moveViewV2(
          viewId: view.id,
          newParentId: view.parentViewId,
          prevViewId: null,
        );
      }

      Log.info('[workspace] end to fix unlistedChildViews');
    }

    if (unlistedChildViews.isEmpty && orphanViews.isEmpty) {
      Log.info('[workspace] all views are healthy');
    }

    Log.info('[workspace] done checking view health');

    return unlistedChildViews;
  }

  static Future<void> checkViewsOutOfSpace({
    bool dryRun = true,
  }) async {
    try {
      final currentWorkspace =
          await UserBackendService.getCurrentWorkspace().getOrThrow();
      final workspaceService =
          WorkspaceService(workspaceId: currentWorkspace.id);
      final publicViews = await workspaceService.getPublicViews().getOrThrow();
      final publicSpaces = publicViews
          .where(
            (e) =>
                e.isSpace && e.spacePermission == SpacePermission.publicToAll,
          )
          .toList();

      if (publicSpaces.isEmpty) {
        Log.info('[workspace] no public spaces found');
        return;
      }

      if (publicViews.length != publicSpaces.length) {
        Log.info(
          '[workspace] found an issue: not all public views are public spaces',
        );

        for (final view in publicViews) {
          if (view.isSpace) {
            continue;
          }

          Log.info(
            '[workspace] found an issue: view is not a public space: $view',
          );

          // move the view to the space
          if (!dryRun) {
            await ViewBackendService.moveViewV2(
              viewId: view.id,
              newParentId: publicSpaces.first.id,
              prevViewId: null,
            );

            Log.info(
              '[workspace] moved view($view) to the public space(${publicSpaces.first})',
            );
          }
        }
      }
    } catch (e) {
      Log.error('[workspace] Failed to check views out of space: $e');
    }
  }

  static void dumpViews(String prefix, List<ViewPB> views) {
    for (int i = 0; i < views.length; i++) {
      final view = views[i];
      Log.info('$prefix $i: $view)');
    }
  }
}
