import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ChecklistProgressBar extends StatefulWidget {
  final double percent;
  const ChecklistProgressBar({required this.percent, Key? key})
      : super(key: key);

  @override
  State<ChecklistProgressBar> createState() => _ChecklistProgressBarState();
}

class _ChecklistProgressBarState extends State<ChecklistProgressBar> {
  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      lineHeight: 4.0,
      percent: widget.percent,
      padding: EdgeInsets.zero,
      progressColor: Theme.of(context).colorScheme.primary,
      backgroundColor: AFThemeExtension.of(context).progressBarBGColor,
      barRadius: const Radius.circular(5),
    );
  }
}
