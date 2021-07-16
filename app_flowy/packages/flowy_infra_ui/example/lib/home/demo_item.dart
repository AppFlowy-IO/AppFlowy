import 'package:flutter/material.dart';

abstract class ListItem {}

abstract class DemoItem extends ListItem {
  String buildTitle();

  void handleTap();
}

class SectionHeaderItem extends ListItem {
  SectionHeaderItem(this.title);

  final String title;

  Widget buildWidget(BuildContext context) => Text(title);
}
