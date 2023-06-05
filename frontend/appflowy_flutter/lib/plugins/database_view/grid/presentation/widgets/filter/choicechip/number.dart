import 'package:flutter/material.dart';

import '../filter_info.dart';
import 'choicechip.dart';

class NumberFilterChoicechip extends StatelessWidget {
  final FilterInfo filterInfo;
  const NumberFilterChoicechip({required this.filterInfo, final Key? key})
      : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return ChoiceChipButton(filterInfo: filterInfo);
  }
}
