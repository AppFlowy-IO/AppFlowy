import 'package:appflowy/mobile/presentation/home/tab/_round_underline_tab_indicator.dart';
import 'package:appflowy/mobile/presentation/home/tab/mobile_space_tab.dart';
import 'package:flutter/material.dart';

class MobileSpaceTabBar extends StatelessWidget {
  const MobileSpaceTabBar({
    super.key,
    this.height = 38.0,
    required this.tabController,
    required this.tabs,
  });

  final double height;
  final List<MobileSpaceTabType> tabs;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final labelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 15.0,
    );
    final unselectedLabelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 15.0,
    );
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 8.0),
      child: TabBar(
        controller: tabController,
        tabs: tabs.map((e) => Tab(text: e.name)).toList(),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: Theme.of(context).primaryColor,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: labelStyle,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
        unselectedLabelStyle: unselectedLabelStyle,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: RoundUnderlineTabIndicator(
          width: 28.0,
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
    );
  }
}
