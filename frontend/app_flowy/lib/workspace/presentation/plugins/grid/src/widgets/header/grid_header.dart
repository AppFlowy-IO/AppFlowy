import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' hide Row;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';
import 'field_editor.dart';
import 'field_cell.dart';

class GridHeaderSliverAdaptor extends StatefulWidget {
  final String gridId;
  final GridFieldCache fieldCache;
  final ScrollController anchorScrollController;
  const GridHeaderSliverAdaptor({
    required this.gridId,
    required this.fieldCache,
    required this.anchorScrollController,
    Key? key,
  }) : super(key: key);

  @override
  State<GridHeaderSliverAdaptor> createState() => _GridHeaderSliverAdaptorState();
}

class _GridHeaderSliverAdaptorState extends State<GridHeaderSliverAdaptor> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<GridHeaderBloc>(param1: widget.gridId, param2: widget.fieldCache)..add(const GridHeaderEvent.initial()),
      child: BlocBuilder<GridHeaderBloc, GridHeaderState>(
        buildWhen: (previous, current) => previous.fields.length != current.fields.length,
        builder: (context, state) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: widget.anchorScrollController,
            child: SizedBox(height: GridSize.headerHeight, child: _GridHeader(gridId: widget.gridId)),
          );

          // return SliverPersistentHeader(
          //   delegate: SliverHeaderDelegateImplementation(gridId: gridId, fields: state.fields),
          //   floating: true,
          //   pinned: true,
          // );
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
    return _GridHeader(gridId: gridId);
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

class _GridHeader extends StatefulWidget {
  final String gridId;
  const _GridHeader({Key? key, required this.gridId}) : super(key: key);

  @override
  State<_GridHeader> createState() => _GridHeaderState();
}

class _GridHeaderState extends State<_GridHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<GridHeaderBloc, GridHeaderState>(
      buildWhen: (previous, current) => previous.fields != current.fields,
      builder: (context, state) {
        final cells = state.fields
            .where((field) => field.visibility)
            .map((field) => GridFieldCellContext(gridId: widget.gridId, field: field))
            .map((ctx) => GridFieldCell(ctx, key: ValueKey(ctx.field.id)))
            .toList();

        return Container(
          color: theme.surface,
          child: RepaintBoundary(
            child: ReorderableRow(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              scrollController: ScrollController(),
              header: const _CellLeading(),
              footer: _CellTrailing(gridId: widget.gridId),
              onReorder: (int oldIndex, int newIndex) {
                Log.info("from $oldIndex to $newIndex");
              },
              children: cells,
            ),
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
