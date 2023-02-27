import 'package:flutter/material.dart';
import '../filter_info.dart';
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
