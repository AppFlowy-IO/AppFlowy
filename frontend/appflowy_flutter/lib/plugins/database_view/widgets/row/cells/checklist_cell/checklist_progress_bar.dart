import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'checklist_cell_bloc.dart';

class ChecklistProgressBar extends StatefulWidget {
  final List<ChecklistSelectOption> tasks;
  final double percent;
  final int segmentLimit = 5;

  const ChecklistProgressBar({
    required this.tasks,
    required this.percent,
    Key? key,
  }) : super(key: key);

  @override
  State<ChecklistProgressBar> createState() => _ChecklistProgressBarState();
}

class _ChecklistProgressBarState extends State<ChecklistProgressBar> {
  @override
  Widget build(BuildContext context) {
    final numFinishedTasks = widget.tasks.where((e) => e.isSelected).length;
    final completedTaskColor = numFinishedTasks == widget.tasks.length
        ? AFThemeExtension.of(context).success
        : Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (widget.tasks.isNotEmpty &&
                  widget.tasks.length <= widget.segmentLimit)
                ...List<Widget>.generate(
                  widget.tasks.length,
                  (index) => Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(2)),
                        color: index < numFinishedTasks
                            ? completedTaskColor
                            : AFThemeExtension.of(context).progressBarBGColor,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 4.0,
                    ),
                  ),
                )
              else
                Expanded(
                  child: LinearPercentIndicator(
                    lineHeight: 4.0,
                    percent: widget.percent,
                    padding: EdgeInsets.zero,
                    progressColor: completedTaskColor,
                    backgroundColor:
                        AFThemeExtension.of(context).progressBarBGColor,
                    barRadius: const Radius.circular(2),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          width: 36,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FlowyText.regular(
              "${(widget.percent * 100).round()}%",
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      ],
    );
  }
}
