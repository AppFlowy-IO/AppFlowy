import 'package:appflowy/mobile/presentation/home/mobile_folders.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MobileSpaceTabType {
  recent,
  spaces,
  favorites;

  String get name {
    switch (this) {
      case MobileSpaceTabType.recent:
        return "Recent";
      case MobileSpaceTabType.spaces:
        return "Spaces";
      case MobileSpaceTabType.favorites:
        return "Favorites";
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
  final List<String> tabs =
      MobileSpaceTabType.values.map((e) => e.name).toList();

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
    final state = context.watch<UserWorkspaceBloc>().state;
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final labelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 15.0,
    );
    final unselectedLabelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 15.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorColor: Theme.of(context).primaryColor,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: labelStyle,
          unselectedLabelStyle: unselectedLabelStyle,
          indicatorWeight: 3,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        const HSpace(12.0),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tabs.map((e) {
              return Scrollbar(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Folders
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: MobileFolders(
                            user: widget.userProfile,
                            workspaceId:
                                state.currentWorkspace?.workspaceId ?? '',
                            showFavorite: false,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
