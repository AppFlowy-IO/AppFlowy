import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_editor.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/setting/property_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../../application/field/field_controller.dart';
import '../../layout/sizes.dart';

class GridPropertyList extends StatefulWidget {
  final String gridId;
  final GridFieldController fieldController;
  const GridPropertyList({
    required this.gridId,
    required this.fieldController,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GridPropertyListState();
}

class _GridPropertyListState extends State<GridPropertyList> {
  late PopoverMutex _popoverMutex;

  @override
  void initState() {
    _popoverMutex = PopoverMutex();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GridPropertyBloc>(
          param1: widget.gridId, param2: widget.fieldController)
        ..add(const GridPropertyEvent.initial()),
      child: BlocBuilder<GridPropertyBloc, GridPropertyState>(
        builder: (context, state) {
          final cells = state.fieldContexts.map((field) {
            return _GridPropertyCell(
              popoverMutex: _popoverMutex,
              gridId: widget.gridId,
              fieldContext: field,
              key: ValueKey(field.id),
            );
          }).toList();

          return ListView.separated(
            controller: ScrollController(),
            shrinkWrap: true,
            itemCount: cells.length,
            itemBuilder: (BuildContext context, int index) {
              return cells[index];
            },
            separatorBuilder: (BuildContext context, int index) {
              return VSpace(GridSize.typeOptionSeparatorHeight);
            },
          );
        },
      ),
    );
  }
}

class _GridPropertyCell extends StatelessWidget {
  final GridFieldContext fieldContext;
  final String gridId;
  final PopoverMutex popoverMutex;
  const _GridPropertyCell({
    required this.gridId,
    required this.fieldContext,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    final checkmark = fieldContext.visibility
        ? svgWidget('home/show', color: theme.iconColor)
        : svgWidget('home/hide', color: theme.iconColor);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: GridSize.typeOptionItemHeight,
            child: _editFieldButton(theme, context),
          ),
        ),
        FlowyIconButton(
          hoverColor: theme.hover,
          width: GridSize.typeOptionItemHeight,
          onPressed: () {
            context.read<GridPropertyBloc>().add(
                GridPropertyEvent.setFieldVisibility(
                    fieldContext.id, !fieldContext.visibility));
          },
          icon: checkmark.padding(all: 6),
        )
      ],
    );
  }

  Widget _editFieldButton(AppTheme theme, BuildContext context) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      offset: const Offset(20, 0),
      constraints: BoxConstraints.loose(const Size(240, 400)),
      child: FlowyButton(
        text: FlowyText.medium(fieldContext.name, fontSize: 12),
        hoverColor: theme.hover,
        leftIcon: svgWidget(fieldContext.fieldType.iconName(),
            color: theme.iconColor),
      ),
      popupBuilder: (BuildContext context) {
        return FieldEditor(
          gridId: gridId,
          fieldName: fieldContext.name,
          typeOptionLoader: FieldTypeOptionLoader(
            gridId: gridId,
            field: fieldContext.field,
          ),
        );
      },
    );
  }
}
