import 'package:flutter/material.dart';

import '../filter_info.dart';
import 'choicechip.dart';

class DateFilterChoicechip extends StatelessWidget {
  final FilterInfo filterInfo;
  const DateFilterChoicechip({required this.filterInfo, final Key? key})
      : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return ChoiceChipButton(filterInfo: filterInfo);
  }
}
