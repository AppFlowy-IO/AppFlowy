import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../../grid/presentation/widgets/header/field_editor.dart';

class DatabasePropertyList extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;
  const DatabasePropertyList({
    required this.viewId,
    required this.fieldController,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DatabasePropertyListState();
}

class _DatabasePropertyListState extends State<DatabasePropertyList> {
  late PopoverMutex _popoverMutex;

  @override
  void initState() {
    _popoverMutex = PopoverMutex();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DatabasePropertyBloc>(
        param1: widget.viewId,
        param2: widget.fieldController,
      )..add(const DatabasePropertyEvent.initial()),
      child: BlocBuilder<DatabasePropertyBloc, DatabasePropertyState>(
        builder: (context, state) {
          final cells = state.fieldContexts.map((field) {
            return _GridPropertyCell(
              popoverMutex: _popoverMutex,
              viewId: widget.viewId,
              fieldInfo: field,
              key: ValueKey(field.id),
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

class _GridPropertyCell extends StatefulWidget {
  final FieldInfo fieldInfo;
  final String viewId;
  final PopoverMutex popoverMutex;

  const _GridPropertyCell({
    required this.viewId,
    required this.fieldInfo,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  State<_GridPropertyCell> createState() => _GridPropertyCellState();
}

class _GridPropertyCellState extends State<_GridPropertyCell> {
  late PopoverController _popoverController;

  @override
  void initState() {
    _popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final checkmark = svgWidget(
      widget.fieldInfo.visibility ? 'home/show' : 'home/hide',
      color: Theme.of(context).iconTheme.color,
    );

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: _editFieldButton(context, checkmark),
    );
  }

  Widget _editFieldButton(BuildContext context, Widget checkmark) {
    return AppFlowyPopover(
      mutex: widget.popoverMutex,
      controller: _popoverController,
      offset: const Offset(8, 0),
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(240, 400)),
      triggerActions: PopoverTriggerFlags.none,
      margin: EdgeInsets.zero,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: FlowyText.medium(
          widget.fieldInfo.name,
          color: AFThemeExtension.of(context).textColor,
        ),
        leftIcon: svgWidget(
          widget.fieldInfo.fieldType.iconName(),
          color: Theme.of(context).iconTheme.color,
        ),
        rightIcon: FlowyIconButton(
          hoverColor: Colors.transparent,
          onPressed: () {
            context.read<DatabasePropertyBloc>().add(
                  DatabasePropertyEvent.setFieldVisibility(
                    widget.fieldInfo.id,
                    !widget.fieldInfo.visibility,
                  ),
                );
          },
          icon: checkmark.padding(all: 6.0),
        ),
        onTap: () => _popoverController.show(),
      ).padding(horizontal: 6.0),
      popupBuilder: (BuildContext context) {
        return FieldEditor(
          viewId: widget.viewId,
          typeOptionLoader: FieldTypeOptionLoader(
            viewId: widget.viewId,
            field: widget.fieldInfo.field,
          ),
        );
      },
    );
  }
}
