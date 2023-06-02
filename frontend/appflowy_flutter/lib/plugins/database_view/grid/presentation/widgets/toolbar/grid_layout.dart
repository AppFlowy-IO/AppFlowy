import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/layout/layout_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../layout/sizes.dart';

class DatabaseLayoutList extends StatefulWidget {
  final String viewId;
  final DatabaseLayoutPB currentLayout;
  const DatabaseLayoutList({
    required this.viewId,
    required this.currentLayout,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DatabaseLayoutListState();
}

class _DatabaseLayoutListState extends State<DatabaseLayoutList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatabaseLayoutBloc(
        viewId: widget.viewId,
        databaseLayout: widget.currentLayout,
      )..add(const DatabaseLayoutEvent.initial()),
      child: BlocBuilder<DatabaseLayoutBloc, DatabaseLayoutState>(
        builder: (context, state) {
          final cells = DatabaseLayoutPB.values.map((layout) {
            final isSelected = state.databaseLayout == layout;
            return DatabaseViewLayoutCell(
              databaseLayout: layout,
              isSelected: isSelected,
              onTap: (selectedLayout) {
                context
                    .read<DatabaseLayoutBloc>()
                    .add(DatabaseLayoutEvent.updateLayout(selectedLayout));
              },
            );
          }).toList();

          return ListView.separated(
            controller: ScrollController(),
            shrinkWrap: true,
            itemCount: cells.length,
            itemBuilder: (BuildContext context, int index) => cells[index],
            separatorBuilder: (BuildContext context, int index) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
            padding: const EdgeInsets.symmetric(vertical: 6.0),
          );
        },
      ),
    );
  }
}

extension DatabaseLayoutExtension on DatabaseLayoutPB {
  String layoutName() {
    switch (this) {
      case DatabaseLayoutPB.Board:
        return LocaleKeys.board_menuName.tr();
      case DatabaseLayoutPB.Calendar:
        return LocaleKeys.calendar_menuName.tr();
      case DatabaseLayoutPB.Grid:
        return LocaleKeys.grid_menuName.tr();
      default:
        return "";
    }
  }

  String iconName() {
    switch (this) {
      case DatabaseLayoutPB.Board:
        return 'editor/board';
      case DatabaseLayoutPB.Calendar:
        return "editor/grid";
      case DatabaseLayoutPB.Grid:
        return "editor/grid";
      default:
        return "";
    }
  }
}

class DatabaseViewLayoutCell extends StatelessWidget {
  final bool isSelected;
  final DatabaseLayoutPB databaseLayout;
  final void Function(DatabaseLayoutPB) onTap;
  const DatabaseViewLayoutCell({
    required this.databaseLayout,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget? checkmark;
    if (isSelected) {
      checkmark = svgWidget("grid/checkmark");
    }

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: FlowyText.medium(
          databaseLayout.layoutName(),
          color: AFThemeExtension.of(context).textColor,
        ),
        leftIcon: svgWidget(
          databaseLayout.iconName(),
          color: Theme.of(context).iconTheme.color,
        ),
        rightIcon: checkmark,
        onTap: () => onTap(databaseLayout),
      ).padding(horizontal: 6.0),
    );
  }
}
