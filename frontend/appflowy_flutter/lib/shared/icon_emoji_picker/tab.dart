import 'package:appflowy/mobile/presentation/home/tab/_round_underline_tab_indicator.dart';
import 'package:flutter/material.dart';

enum PickerTabType {
  emoji,
  icon;

  String get tr {
    switch (this) {
      case PickerTabType.emoji:
        return 'Emojis';
      case PickerTabType.icon:
        return 'Icons';
    }
  }
}

class PickerTab extends StatelessWidget {
  const PickerTab({
    super.key,
    required this.controller,
    required this.tabs,
  });

  final List<PickerTabType> tabs;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final style = baseStyle?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 14.0,
      height: 16.0 / 14.0,
    );
    return TabBar(
      controller: controller,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: Theme.of(context).colorScheme.primary,
      isScrollable: true,
      labelStyle: style,
      labelColor: baseStyle?.color,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
      unselectedLabelStyle: style?.copyWith(
        color: Theme.of(context).hintColor,
      ),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      indicator: RoundUnderlineTabIndicator(
        width: 34.0,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
      ),
      tabs: tabs
          .map(
            (tab) => Tab(
              text: tab.tr,
            ),
          )
          .toList(),
    );
  }
}
