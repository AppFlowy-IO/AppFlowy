import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checklist_cell/checklist_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ChecklistProgressBar extends StatelessWidget {
  final double percent;
  const ChecklistProgressBar({required this.percent, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      lineHeight: 10.0,
      percent: percent,
      padding: EdgeInsets.zero,
      progressColor: percent < 1.0
          ? SelectOptionColorPB.Blue.toColor(context)
          : SelectOptionColorPB.Green.toColor(context),
      backgroundColor: AFThemeExtension.of(context).progressBarBGColor,
      barRadius: const Radius.circular(5),
    );
  }
}

class SliverChecklistProgressBar extends StatelessWidget {
  const SliverChecklistProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverChecklistProgressBarDelegate(),
    );
  }
}

class _SliverChecklistProgressBarDelegate
    extends SliverPersistentHeaderDelegate {
  _SliverChecklistProgressBarDelegate();

  double fixHeight = 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const _AutoFocusTextField();
  }

  @override
  double get maxExtent => fixHeight;

  @override
  double get minExtent => fixHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class _AutoFocusTextField extends StatefulWidget {
  const _AutoFocusTextField();

  @override
  State<_AutoFocusTextField> createState() => _AutoFocusTextFieldState();
}

class _AutoFocusTextFieldState extends State<_AutoFocusTextField> {
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistCellEditorBloc, ChecklistCellEditorState>(
      builder: (context, state) {
        return BlocListener<ChecklistCellEditorBloc, ChecklistCellEditorState>(
          listenWhen: (previous, current) =>
              previous.createOption != current.createOption,
          listener: (context, state) {
            if (_focusNode.canRequestFocus) {
              _focusNode.requestFocus();
            }
          },
          child: Container(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: GridSize.typeOptionContentInsets,
              child: Column(
                children: [
                  FlowyTextField(
                    autoFocus: true,
                    focusNode: _focusNode,
                    autoClearWhenDone: true,
                    submitOnLeave: true,
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: ChecklistProgressBar(percent: state.percent),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
