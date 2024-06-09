import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/setting/database_setting_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/widgets.dart';

class DatabaseSettingsList extends StatefulWidget {
  const DatabaseSettingsList({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  State<StatefulWidget> createState() => _DatabaseSettingsListState();
}

class _DatabaseSettingsListState extends State<DatabaseSettingsList> {
  late final PopoverMutex popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    final cells =
        actionsForDatabaseLayout(widget.databaseController.databaseLayout)
            .map(
              (action) => action.build(
                context,
                widget.databaseController,
                popoverMutex,
              ),
            )
            .toList();

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: cells.length,
      separatorBuilder: (context, index) =>
          VSpace(GridSize.typeOptionSeparatorHeight),
      physics: StyledScrollPhysics(),
      itemBuilder: (BuildContext context, int index) => cells[index],
    );
  }
}

/// Returns the list of actions that should be shown for the given database layout.
List<DatabaseSettingAction> actionsForDatabaseLayout(DatabaseLayoutPB? layout) {
  switch (layout) {
    case DatabaseLayoutPB.Board:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
        if (!PlatformExtension.isMobile) DatabaseSettingAction.showGroup,
      ];
    case DatabaseLayoutPB.Calendar:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
        DatabaseSettingAction.showCalendarLayout,
      ];
    case DatabaseLayoutPB.Grid:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
      ];
    default:
      return [];
  }
}
