import 'package:app_flowy/workspace/application/grid/row_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GridFooter extends StatelessWidget {
  const GridFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: GridSize.footerHeight,
        child: Padding(
          padding: GridSize.headerContentInsets,
          child: Row(
            children: [
              SizedBox(width: GridSize.leadingHeaderPadding),
              const SizedBox(width: 120, child: AddRowButton()),
            ],
          ),
        ),
      ),
    );
  }
}

class AddRowButton extends StatelessWidget {
  const AddRowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      text: const FlowyText.medium('New row', fontSize: 12),
      hoverColor: theme.hover,
      onTap: () => context.read<RowBloc>().add(const RowEvent.createRow()),
      icon: svg("home/add"),
    );
  }
}
