import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_editor.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/setting/property_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
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
              fieldInfo: field,
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
  final GridFieldInfo fieldInfo;
  final String gridId;
  final PopoverMutex popoverMutex;
  const _GridPropertyCell({
    required this.gridId,
    required this.fieldInfo,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final checkmark = svgWidget(
      fieldInfo.visibility ? 'home/show' : 'home/hide',
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: GridSize.typeOptionItemHeight,
            child: _editFieldButton(context),
          ),
        ),
        FlowyIconButton(
          width: GridSize.typeOptionItemHeight,
          onPressed: () {
            context.read<GridPropertyBloc>().add(
                GridPropertyEvent.setFieldVisibility(
                    fieldInfo.id, !fieldInfo.visibility));
          },
          icon: checkmark.padding(all: 6),
        )
      ],
    );
  }

  Widget _editFieldButton(BuildContext context) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      offset: const Offset(20, 0),
      constraints: BoxConstraints.loose(const Size(240, 400)),
      child: FlowyButton(
        text: FlowyText.medium(fieldInfo.name, fontSize: 12),
        leftIcon: svgWidget(
          fieldInfo.fieldType.iconName(),
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      popupBuilder: (BuildContext context) {
        return FieldEditor(
          gridId: gridId,
          fieldName: fieldInfo.name,
          typeOptionLoader: FieldTypeOptionLoader(
            gridId: gridId,
            field: fieldInfo.field,
          ),
        );
      },
    );
  }
}
