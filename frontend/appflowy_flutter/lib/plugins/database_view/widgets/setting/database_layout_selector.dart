import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_item_widget.dart';
import 'package:appflowy/plugins/database_view/application/layout/layout_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/database_layout_ext.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../grid/presentation/layout/sizes.dart';

class DatabaseLayoutSelector extends StatefulWidget {
  const DatabaseLayoutSelector({
    super.key,
    required this.viewId,
    required this.currentLayout,
  });

  final String viewId;
  final DatabaseLayoutPB currentLayout;

  @override
  State<StatefulWidget> createState() => _DatabaseLayoutSelectorState();
}

class _DatabaseLayoutSelectorState extends State<DatabaseLayoutSelector> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatabaseLayoutBloc(
        viewId: widget.viewId,
        databaseLayout: widget.currentLayout,
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

          return ListView.separated(
            controller: ScrollController(),
            shrinkWrap: true,
            itemCount: cells.length,
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            itemBuilder: (_, int index) => cells[index],
            separatorBuilder: (_, __) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
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
    if (PlatformExtension.isMobile) {
      return MobileDatabaseViewLayoutCell(
        isSelected: isSelected,
        databaseLayout: databaseLayout,
        onTap: onTap,
      );
    }

    return DesktopDatabaseViewLayoutCell(
      isSelected: isSelected,
      databaseLayout: databaseLayout,
      onTap: onTap,
    );
  }
}

class DesktopDatabaseViewLayoutCell extends StatelessWidget {
  const DesktopDatabaseViewLayoutCell({
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
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: FlowyText.medium(
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

class MobileDatabaseViewLayoutCell extends StatelessWidget {
  const MobileDatabaseViewLayoutCell({
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
    return MobileSettingItem(
      padding: EdgeInsets.zero,
      name: databaseLayout.layoutName,
      trailing: isSelected ? const FlowySvg(FlowySvgs.check_s) : null,
      leadingIcon: FlowySvg(
        databaseLayout.icon,
        color: Theme.of(context).iconTheme.color,
        size: const Size.square(18),
      ),
      onTap: () => onTap(databaseLayout),
    );
  }
}
