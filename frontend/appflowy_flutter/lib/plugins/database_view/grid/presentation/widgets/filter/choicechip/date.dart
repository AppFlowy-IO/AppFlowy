import 'package:appflowy/plugins/database_view/application/filter/filter_info.dart';
import 'package:flutter/material.dart';

import 'choicechip.dart';

class DateFilterChoicechip extends StatelessWidget {
  final FilterInfo filterInfo;
  const DateFilterChoicechip({required this.filterInfo, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChoiceChipButton(filterInfo: filterInfo);
  }
}
