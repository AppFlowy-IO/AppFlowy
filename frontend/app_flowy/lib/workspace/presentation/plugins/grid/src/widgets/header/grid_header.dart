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

import 'field_editor.dart';
import 'field_cell.dart';

class GridHeaderSliverAdaptor extends StatelessWidget {
  final String gridId;
  final List<Field> fields;

  const GridHeaderSliverAdaptor({required this.gridId, required this.fields, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GridHeaderBloc>(param1: gridId, param2: fields)..add(const GridHeaderEvent.initial()),
      child: BlocBuilder<GridHeaderBloc, GridHeaderState>(
        builder: (context, state) {
          return SliverPersistentHeader(
            delegate: SliverHeaderDelegateImplementation(gridId: gridId, fields: fields),
            floating: true,
            pinned: true,
          );
        },
      ),
    );
  }
}

class SliverHeaderDelegateImplementation extends SliverPersistentHeaderDelegate {
  final String gridId;
  final List<Field> fields;

  SliverHeaderDelegateImplementation({required this.gridId, required this.fields});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _GridHeader(gridId: gridId, fields: fields, key: ObjectKey(fields));
  }

  @override
  double get maxExtent => GridSize.headerHeight;

  @override
  double get minExtent => GridSize.headerHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is SliverHeaderDelegateImplementation) {
      return fields.length != oldDelegate.fields.length;
    }
    return true;
  }
}

class _GridHeader extends StatelessWidget {
  final String gridId;
  final List<Field> fields;

  const _GridHeader({
    Key? key,
    required this.gridId,
    required this.fields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<GridHeaderBloc, GridHeaderState>(
      builder: (context, state) {
        final cells = state.fields
            .map((field) => GridFieldCellContext(gridId: gridId, field: field))
            .map((ctx) => GridFieldCell(ctx, key: ValueKey(ctx.field.id)))
            .toList();

        return Container(
          color: theme.surface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CellLeading(),
              ...cells,
              _CellTrailing(gridId: gridId),
            ],
          ),
        );
      },
    );
  }
}

class _CellLeading extends StatelessWidget {
  const _CellLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GridSize.leadingHeaderPadding,
    );
  }
}

class _CellTrailing extends StatelessWidget {
  final String gridId;
  const _CellTrailing({required this.gridId, Key? key}) : super(key: key);

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
      onTap: () => FieldEditor(
        gridId: gridId,
        fieldContextLoader: NewFieldContextLoader(gridId: gridId),
      ).show(context),
      leftIcon: svgWidget("home/add"),
    );
  }
}
