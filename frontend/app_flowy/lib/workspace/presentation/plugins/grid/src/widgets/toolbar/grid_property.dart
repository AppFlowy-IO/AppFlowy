import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/application/grid/grid_service.dart';
import 'package:app_flowy/workspace/application/grid/setting/property_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_type_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Field;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

class GridPropertyList extends StatelessWidget with FlowyOverlayDelegate {
  final String gridId;
  final GridFieldCache fieldCache;
  const GridPropertyList({
    required this.gridId,
    required this.fieldCache,
    Key? key,
  }) : super(key: key);

  void show(BuildContext context) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.loose(const Size(260, 400)),
      ),
      identifier: identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomRight,
      style: FlowyOverlayStyle(blur: false),
      delegate: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<GridPropertyBloc>(param1: gridId, param2: fieldCache)..add(const GridPropertyEvent.initial()),
      child: BlocBuilder<GridPropertyBloc, GridPropertyState>(
        builder: (context, state) {
          final cells = state.fields.map((field) {
            return _GridPropertyCell(gridId: gridId, field: field, key: ValueKey(field.id));
          }).toList();

          return ListView.separated(
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

  String identifier() {
    return (GridPropertyList).toString();
  }

  @override
  bool asBarrier() => true;
}

class _GridPropertyCell extends StatelessWidget {
  final Field field;
  final String gridId;
  const _GridPropertyCell({required this.gridId, required this.field, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    final checkmark = field.visibility
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
            context.read<GridPropertyBloc>().add(GridPropertyEvent.setFieldVisibility(field.id, !field.visibility));
          },
          icon: checkmark.padding(all: 6),
        )
      ],
    );
  }

  FlowyButton _editFieldButton(AppTheme theme, BuildContext context) {
    return FlowyButton(
      text: FlowyText.medium(field.name, fontSize: 12),
      hoverColor: theme.hover,
      leftIcon: svgWidget(field.fieldType.iconName(), color: theme.iconColor),
      onTap: () {
        FieldEditor(
          gridId: gridId,
          fieldName: field.name,
          contextLoader: DefaultFieldContextLoader(gridId: gridId, field: field),
        ).show(context, anchorDirection: AnchorDirection.bottomRight);
      },
    );
  }
}
