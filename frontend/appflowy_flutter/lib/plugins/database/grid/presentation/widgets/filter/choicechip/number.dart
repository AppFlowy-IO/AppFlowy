import 'package:flutter/material.dart';

import '../filter_info.dart';
import 'choicechip.dart';

class NumberFilterChoicechip extends StatelessWidget {
  final FilterInfo filterInfo;
  const NumberFilterChoicechip({required this.filterInfo, super.key});

  @override
  Widget build(BuildContext context) {
    return ChoiceChipButton(filterInfo: filterInfo);
  }
}
