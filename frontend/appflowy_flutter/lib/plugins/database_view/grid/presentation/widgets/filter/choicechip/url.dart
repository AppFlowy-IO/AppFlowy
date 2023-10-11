import 'package:appflowy/plugins/database_view/application/filter/filter_info.dart';
import 'package:flutter/material.dart';

import 'choicechip.dart';

class URLFilterChoicechip extends StatelessWidget {
  final String viewId;
  final FilterInfo filterInfo;
  const URLFilterChoicechip({
    required this.filterInfo,
    required this.viewId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChipButton(filterInfo: filterInfo);
  }
}
