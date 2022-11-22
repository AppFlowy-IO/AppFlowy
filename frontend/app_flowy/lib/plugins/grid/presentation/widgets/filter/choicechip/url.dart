import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:flutter/material.dart';
import 'choicechip.dart';

class URLFilterChoicechip extends StatelessWidget {
  final FilterInfo filterInfo;
  const URLFilterChoicechip({required this.filterInfo, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChoiceChipButton(filterInfo: filterInfo);
  }
}
