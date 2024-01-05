import 'package:flutter/material.dart';

import '../filter_info.dart';
import 'choicechip.dart';

class DateFilterChoicechip extends StatelessWidget {
  final FilterInfo filterInfo;
  const DateFilterChoicechip({required this.filterInfo, super.key});

  @override
  Widget build(BuildContext context) {
    return ChoiceChipButton(filterInfo: filterInfo);
  }
}
