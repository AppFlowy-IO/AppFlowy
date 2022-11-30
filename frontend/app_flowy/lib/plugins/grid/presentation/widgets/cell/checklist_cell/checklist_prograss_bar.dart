import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/cell/checklist_cell_editor_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ChecklistPrograssBar extends StatelessWidget {
  final double percent;
  const ChecklistPrograssBar({required this.percent, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      lineHeight: 10.0,
      percent: percent,
      padding: EdgeInsets.zero,
      progressColor: Theme.of(context).colorScheme.primary,
      backgroundColor: AFThemeExtension.of(context).tint9,
      barRadius: const Radius.circular(5),
    );
  }
}

class SliverChecklistPrograssBar extends StatelessWidget {
  const SliverChecklistPrograssBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverChecklistPrograssBarDelegate(),
    );
  }
}

class _SliverChecklistPrograssBarDelegate
    extends SliverPersistentHeaderDelegate {
  _SliverChecklistPrograssBarDelegate();

  double fixHeight = 80;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return BlocBuilder<ChecklistCellEditorBloc, ChecklistCellEditorState>(
      builder: (context, state) {
        return Column(
          children: [
            if (state.percent != 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ChecklistPrograssBar(percent: state.percent),
              ),
            FlowyTextField(
              hintText: LocaleKeys.grid_checklist_panelTitle.tr(),
              onChanged: (text) {
                context
                    .read<ChecklistCellEditorBloc>()
                    .add(ChecklistCellEditorEvent.filterOption(text));
              },
              onSubmitted: (text) {
                context
                    .read<ChecklistCellEditorBloc>()
                    .add(ChecklistCellEditorEvent.newOption(text));
              },
            )
          ],
        );
      },
    );
  }

  @override
  double get maxExtent => fixHeight;

  @override
  double get minExtent => fixHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
