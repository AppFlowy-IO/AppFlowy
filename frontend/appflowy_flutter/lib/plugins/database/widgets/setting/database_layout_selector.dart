import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/layout/layout_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/database_layout_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DatabaseLayoutSelector extends StatelessWidget {
  const DatabaseLayoutSelector({
    super.key,
    required this.viewId,
    required this.databaseController,
  });

  final String viewId;
  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatabaseLayoutBloc(
        viewId: viewId,
        databaseLayout: databaseController.databaseLayout,
      )..add(const DatabaseLayoutEvent.initial()),
      child: BlocBuilder<DatabaseLayoutBloc, DatabaseLayoutState>(
        builder: (context, state) {
          final cells = DatabaseLayoutPB.values
              .map(
                (layout) => DatabaseViewLayoutCell(
                  databaseLayout: layout,
                  isSelected: state.databaseLayout == layout,
                  onTap: (selectedLayout) => context
                      .read<DatabaseLayoutBloc>()
                      .add(DatabaseLayoutEvent.updateLayout(selectedLayout)),
                ),
              )
              .toList();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: cells.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (_, int index) => cells[index],
                  separatorBuilder: (_, __) =>
                      VSpace(GridSize.typeOptionSeparatorHeight),
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.fromLTRB(8, 4, 8, 0),
                  color: AFThemeExtension.of(context).borderColor,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                  child: SizedBox(
                    height: 30,
                    child: FlowyButton(
                      resetHoverOnRebuild: false,
                      text: FlowyText(
                        LocaleKeys.grid_settings_compactMode.tr(),
                        lineHeight: 1.0,
                      ),
                      onTap: () {
                        databaseController.setCompactMode(
                          !databaseController.compactModeNotifier.value,
                        );
                      },
                      rightIcon: ValueListenableBuilder(
                        valueListenable: databaseController.compactModeNotifier,
                        builder: (context, compactMode, child) {
                          return Toggle(
                            value: compactMode,
                            duration: Duration.zero,
                            onChanged: (value) =>
                                databaseController.setCompactMode(value),
                            padding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DatabaseViewLayoutCell extends StatelessWidget {
  const DatabaseViewLayoutCell({
    super.key,
    required this.isSelected,
    required this.databaseLayout,
    required this.onTap,
  });

  final bool isSelected;
  final DatabaseLayoutPB databaseLayout;
  final void Function(DatabaseLayoutPB) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: 30,
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: FlowyText(
            lineHeight: 1.0,
            databaseLayout.layoutName,
            color: AFThemeExtension.of(context).textColor,
          ),
          leftIcon: FlowySvg(
            databaseLayout.icon,
            color: Theme.of(context).iconTheme.color,
          ),
          rightIcon: isSelected ? const FlowySvg(FlowySvgs.check_s) : null,
          onTap: () => onTap(databaseLayout),
        ),
      ),
    );
  }
}
