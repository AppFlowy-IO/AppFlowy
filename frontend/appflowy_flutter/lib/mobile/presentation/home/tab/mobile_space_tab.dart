import 'package:appflowy/mobile/presentation/favorite/mobile_favorite_folder.dart';
import 'package:appflowy/mobile/presentation/home/home_space/home_space.dart';
import 'package:appflowy/mobile/presentation/home/recent_folder/recent_space.dart';
import 'package:appflowy/mobile/presentation/home/tab/_tab_bar.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum MobileSpaceTabType {
  recent,
  spaces,
  favorites;

  String get name {
    switch (this) {
      case MobileSpaceTabType.recent:
        return 'Recent';
      case MobileSpaceTabType.spaces:
        return 'Spaces';
      case MobileSpaceTabType.favorites:
        return 'Favorites';
    }
  }
}

class MobileSpaceTab extends StatefulWidget {
  const MobileSpaceTab({super.key, required this.userProfile});

  final UserProfilePB userProfile;

  @override
  State<MobileSpaceTab> createState() => _MobileSpaceTabState();
}

class _MobileSpaceTabState extends State<MobileSpaceTab>
    with SingleTickerProviderStateMixin {
  final tabs = MobileSpaceTabType.values;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileSpaceTabBar(tabController: _tabController, tabs: tabs),
        const HSpace(12.0),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _buildTabs(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTabs() {
    return tabs.map((tab) {
      switch (tab) {
        case MobileSpaceTabType.recent:
          return const MobileRecentSpace();
        case MobileSpaceTabType.spaces:
          return MobileHomeSpace(userProfile: widget.userProfile);
        case MobileSpaceTabType.favorites:
          return MobileFavoritePageFolder(userProfile: widget.userProfile);
        default:
          throw Exception('Unknown tab type: $tab');
      }
    }).toList();
  }
}
