import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/setting/group_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/board_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;

class DatabaseGroupList extends StatelessWidget {
  final String viewId;
  final DatabaseController databaseController;
  final VoidCallback onDismissed;
  const DatabaseGroupList({
    required this.viewId,
    required this.databaseController,
    required this.onDismissed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatabaseGroupBloc(
        viewId: viewId,
        databaseController: databaseController,
      )..add(const DatabaseGroupEvent.initial()),
      child: BlocBuilder<DatabaseGroupBloc, DatabaseGroupState>(
        builder: (context, state) {
          final showHideUngroupedToggle = state.fieldInfos.any(
            (field) =>
                field.canBeGroup &&
                field.isGroupField &&
                field.fieldType != FieldType.Checkbox,
          );
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
                        child: FlowyText.medium(
                          LocaleKeys.board_showUngrouped.tr(),
                        ),
                      ),
                      Toggle(
                        value: !state.layoutSettings.hideUngroupedColumn,
                        onChanged: (value) =>
                            _updateLayoutSettings(state.layoutSettings, value),
                        style: ToggleStyle.big,
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
                child: FlowyText.medium(
                  LocaleKeys.board_groupBy.tr(),
                  textAlign: TextAlign.left,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            ...state.fieldInfos.where((fieldInfo) => fieldInfo.canBeGroup).map(
                  (fieldInfo) => _GridGroupCell(
                    fieldInfo: fieldInfo,
                    onSelected: onDismissed,
                    key: ValueKey(fieldInfo.id),
                  ),
                ),
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
  final VoidCallback onSelected;
  final FieldInfo fieldInfo;
  const _GridGroupCell({
    required this.fieldInfo,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? rightIcon;
    if (fieldInfo.isGroupField) {
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
          text: FlowyText.medium(
            fieldInfo.name,
            color: AFThemeExtension.of(context).textColor,
          ),
          leftIcon: FlowySvg(
            fieldInfo.fieldType.icon(),
            color: Theme.of(context).iconTheme.color,
          ),
          rightIcon: rightIcon,
          onTap: () {
            context.read<DatabaseGroupBloc>().add(
                  DatabaseGroupEvent.setGroupByField(
                    fieldInfo.id,
                    fieldInfo.fieldType,
                  ),
                );
            onSelected();
          },
        ),
      ),
    );
  }
}
