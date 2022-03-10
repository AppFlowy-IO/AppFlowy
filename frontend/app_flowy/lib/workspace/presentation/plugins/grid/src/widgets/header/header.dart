import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/column_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'header_cell.dart';

class GridHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<Field> fields;

  GridHeaderDelegate(this.fields);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GridHeader(fields: fields);
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
  const GridHeader({required this.fields, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ColumnBloc>(param1: fields)..add(const ColumnEvent.initial()),
      child: BlocBuilder<ColumnBloc, ColumnState>(
        builder: (context, state) {
          final headers = state.fields
              .map(
                (field) => HeaderCellContainer(
                  width: field.width.toDouble(),
                  child: HeaderCell(field),
                ),
              )
              .toList();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LeadingHeaderCell(),
              ...headers,
              const TrailingHeaderCell(),
            ],
          );
        },
      ),
    );
  }
}

class LeadingHeaderCell extends StatelessWidget {
  const LeadingHeaderCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GridSize.leadingHeaderPadding,
    );
  }
}

class TrailingHeaderCell extends StatelessWidget {
  const TrailingHeaderCell({Key? key}) : super(key: key);

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
      child: const CreateColumnButton(),
    );
  }
}

class CreateColumnButton extends StatelessWidget {
  const CreateColumnButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      text: const FlowyText.medium('New column', fontSize: 12),
      hoverColor: theme.hover,
      onTap: () => context.read<ColumnBloc>().add(const ColumnEvent.createColumn()),
      icon: svg("home/add"),
    );
  }
}
