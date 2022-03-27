import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' hide Row;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_field_pannel.dart';
import 'grid_header_cell.dart';

class GridHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String gridId;
  final List<Field> fields;

  GridHeaderDelegate({required this.gridId, required this.fields});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GridHeader(gridId: gridId, fields: fields, key: ObjectKey(fields));
  }

  @override
  double get maxExtent => GridSize.headerHeight;

  @override
  double get minExtent => GridSize.headerHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is GridHeaderDelegate) {
      return fields != oldDelegate.fields;
    }
    return false;
  }
}

class GridHeader extends StatelessWidget {
  final List<Field> fields;
  final String gridId;
  const GridHeader({required this.gridId, required this.fields, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider(
      create: (context) {
        final bloc = getIt<GridHeaderBloc>(param1: gridId, param2: fields);
        bloc.add(const GridHeaderEvent.initial());
        return bloc;
      },
      child: BlocBuilder<GridHeaderBloc, GridHeaderState>(
        builder: (context, state) {
          final cells = state.fields.map(
            (field) => GridHeaderCell(
              GridFieldData(gridId: gridId, field: field),
            ),
          );

          final row = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderLeading(),
              ...cells,
              _HeaderTrailing(gridId: gridId),
            ],
          );

          return Container(color: theme.surface, child: row);
        },
      ),
    );
  }
}

class _HeaderLeading extends StatelessWidget {
  const _HeaderLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GridSize.leadingHeaderPadding,
    );
  }
}

class _HeaderTrailing extends StatelessWidget {
  final String gridId;
  const _HeaderTrailing({required this.gridId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final borderSide = BorderSide(color: theme.shader4, width: 0.4);
    return Container(
      width: GridSize.trailHeaderPadding,
      decoration: BoxDecoration(
        border: Border(top: borderSide, bottom: borderSide),
      ),
      padding: GridSize.headerContentInsets,
      child: CreateFieldButton(gridId: gridId),
    );
  }
}

class CreateFieldButton extends StatelessWidget {
  final String gridId;
  const CreateFieldButton({required this.gridId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      text: const FlowyText.medium('New column', fontSize: 12),
      hoverColor: theme.hover,
      onTap: () => CreateFieldPannel(gridId: gridId).show(context, gridId),
      leftIcon: svg("home/add"),
    );
  }
}
