import 'package:appflowy/mobile/presentation/home/favorite_folder/favorite_space.dart';
import 'package:appflowy/mobile/presentation/home/home_space/home_space.dart';
import 'package:appflowy/mobile/presentation/home/recent_folder/recent_space.dart';
import 'package:appflowy/mobile/presentation/home/tab/_tab_bar.dart';
import 'package:appflowy/mobile/presentation/home/tab/space_order_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class MobileSpaceTab extends StatefulWidget {
  const MobileSpaceTab({super.key, required this.userProfile});

  final UserProfilePB userProfile;

  @override
  State<MobileSpaceTab> createState() => _MobileSpaceTabState();
}

class _MobileSpaceTabState extends State<MobileSpaceTab>
    with SingleTickerProviderStateMixin {
  TabController? tabController;

  @override
  void dispose() {
    tabController?.removeListener(_onTabChange);
    tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: widget.userProfile,
      child: BlocBuilder<SpaceOrderBloc, SpaceOrderState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SizedBox.shrink();
          }

          _initTabController(state);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MobileSpaceTabBar(
                tabController: tabController!,
                tabs: state.tabsOrder,
                onReorder: (from, to) {
                  context.read<SpaceOrderBloc>().add(
                        SpaceOrderEvent.reorder(from, to),
                      );
                },
              ),
              const HSpace(12.0),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: _buildTabs(state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _initTabController(SpaceOrderState state) {
    if (tabController != null) {
      return;
    }
    tabController = TabController(
      length: state.tabsOrder.length,
      vsync: this,
      initialIndex: state.tabsOrder.indexOf(state.defaultTab),
    );
    tabController?.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (tabController == null) {
      return;
    }
    context.read<SpaceOrderBloc>().add(
          SpaceOrderEvent.open(
            tabController!.index,
          ),
        );
  }

  List<Widget> _buildTabs(SpaceOrderState state) {
    return state.tabsOrder.map((tab) {
      switch (tab) {
        case MobileSpaceTabType.recent:
          return const MobileRecentSpace();
        case MobileSpaceTabType.spaces:
          return MobileHomeSpace(userProfile: widget.userProfile);
        case MobileSpaceTabType.favorites:
          return MobileFavoriteSpace(userProfile: widget.userProfile);
        default:
          throw Exception('Unknown tab type: $tab');
      }
    }).toList();
  }
}
