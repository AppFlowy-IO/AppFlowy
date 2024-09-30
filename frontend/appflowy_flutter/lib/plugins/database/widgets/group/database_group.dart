import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/setting/group_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/desktop_field_cell.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;

class DatabaseGroupList extends StatelessWidget {
  const DatabaseGroupList({
    super.key,
    required this.viewId,
    required this.databaseController,
    required this.onDismissed,
  });

  final String viewId;
  final DatabaseController databaseController;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatabaseGroupBloc(
        viewId: viewId,
        databaseController: databaseController,
      )..add(const DatabaseGroupEvent.initial()),
      child: BlocBuilder<DatabaseGroupBloc, DatabaseGroupState>(
        builder: (context, state) {
          final field = state.fieldInfos.firstWhereOrNull(
            (field) => field.fieldType.canBeGroup && field.isGroupField,
          );
          final showHideUngroupedToggle =
              field?.fieldType != FieldType.Checkbox;

          DateGroupConfigurationPB? config;
          if (field != null) {
            final gs = state.groupSettings
                .firstWhereOrNull((gs) => gs.fieldId == field.id);
            config = gs != null
                ? DateGroupConfigurationPB.fromBuffer(gs.content)
                : null;
          }

          final children = [
            if (showHideUngroupedToggle) ...[
              SizedBox(
                height: GridSize.popoverItemHeight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: FlowyText(
                          LocaleKeys.board_showUngrouped.tr(),
                        ),
                      ),
                      Toggle(
                        value: !state.layoutSettings.hideUngroupedColumn,
                        onChanged: (value) =>
                            _updateLayoutSettings(state.layoutSettings, value),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const TypeOptionSeparator(spacing: 0),
            ],
            SizedBox(
              height: GridSize.popoverItemHeight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: FlowyText(
                  LocaleKeys.board_groupBy.tr(),
                  textAlign: TextAlign.left,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            ...state.fieldInfos
                .where((fieldInfo) => fieldInfo.fieldType.canBeGroup)
                .map(
                  (fieldInfo) => _GridGroupCell(
                    fieldInfo: fieldInfo,
                    name: fieldInfo.name,
                    checked: fieldInfo.isGroupField,
                    onSelected: onDismissed,
                    key: ValueKey(fieldInfo.id),
                  ),
                ),
            if (field?.fieldType.groupConditions.isNotEmpty ?? false) ...[
              const TypeOptionSeparator(spacing: 0),
              SizedBox(
                height: GridSize.popoverItemHeight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: FlowyText(
                    LocaleKeys.board_groupCondition.tr(),
                    textAlign: TextAlign.left,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
              ...field!.fieldType.groupConditions.map(
                (condition) => _GridGroupCell(
                  fieldInfo: field,
                  name: condition.name,
                  condition: condition.value,
                  onSelected: onDismissed,
                  checked: config?.condition == condition,
                ),
              ),
            ],
          ];

          return ListView.separated(
            shrinkWrap: true,
            itemCount: children.length,
            itemBuilder: (BuildContext context, int index) => children[index],
            separatorBuilder: (BuildContext context, int index) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
            padding: const EdgeInsets.symmetric(vertical: 6.0),
          );
        },
      ),
    );
  }

  Future<void> _updateLayoutSettings(
    BoardLayoutSettingPB layoutSettings,
    bool hideUngrouped,
  ) {
    layoutSettings.freeze();
    final newLayoutSetting = layoutSettings.rebuild((message) {
      message.hideUngroupedColumn = hideUngrouped;
    });
    return databaseController.updateLayoutSetting(
      boardLayoutSetting: newLayoutSetting,
    );
  }
}

class _GridGroupCell extends StatelessWidget {
  const _GridGroupCell({
    super.key,
    required this.fieldInfo,
    required this.onSelected,
    required this.checked,
    required this.name,
    this.condition = 0,
  });

  final FieldInfo fieldInfo;
  final VoidCallback onSelected;
  final bool checked;
  final int condition;
  final String name;

  @override
  Widget build(BuildContext context) {
    Widget? rightIcon;
    if (checked) {
      rightIcon = const Padding(
        padding: EdgeInsets.all(2.0),
        child: FlowySvg(FlowySvgs.check_s),
      );
    }

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: FlowyText(
            name,
            color: AFThemeExtension.of(context).textColor,
            lineHeight: 1.0,
          ),
          leftIcon: FieldIcon(fieldInfo: fieldInfo),
          rightIcon: rightIcon,
          onTap: () {
            List<int> settingContent = [];
            switch (fieldInfo.fieldType) {
              case FieldType.DateTime:
                final config = DateGroupConfigurationPB()
                  ..condition = DateConditionPB.values[condition];
                settingContent = config.writeToBuffer();
                break;
              default:
            }
            context.read<DatabaseGroupBloc>().add(
                  DatabaseGroupEvent.setGroupByField(
                    fieldInfo.id,
                    fieldInfo.fieldType,
                    settingContent,
                  ),
                );
            onSelected();
          },
        ),
      ),
    );
  }
}
