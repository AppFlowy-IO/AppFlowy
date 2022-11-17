import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';

class FilterButton extends StatefulWidget {
  FilterButton({Key? key}) : super(key: key);

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton> {
  @override
  Widget build(BuildContext context) {
    return FlowyTextButton('Filter');
  }
}
