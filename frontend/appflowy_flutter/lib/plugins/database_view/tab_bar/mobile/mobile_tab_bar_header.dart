import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/database_view/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/mobile_database_controls.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../grid/presentation/grid_page.dart';

class MobileTabBarHeader extends StatefulWidget {
  const MobileTabBarHeader({super.key});

  @override
  State<MobileTabBarHeader> createState() => _MobileTabBarHeaderState();
}

class _MobileTabBarHeaderState extends State<MobileTabBarHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Expanded(child: _DatabaseViewList()),
          const HSpace(10),
          BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
            builder: (context, state) {
              final currentView = state.tabBars.firstWhereIndexedOrNull(
                (index, tabBar) => index == state.selectedIndex,
              );

              if (currentView == null) {
                return const SizedBox.shrink();
              }

              return MobileDatabaseControls(
                controller: state
                    .tabBarControllerByViewId[currentView.viewId]!.controller,
                toggleExtension: ToggleExtensionNotifier(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DatabaseViewList extends StatelessWidget {
  const _DatabaseViewList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
      builder: (context, state) {
        final currentView = state.tabBars.firstWhereIndexedOrNull(
          (index, tabBar) => index == state.selectedIndex,
        );

        if (currentView == null) {
          return const SizedBox.shrink();
        }

        final children = state.tabBars.mapIndexed((index, tabBar) {
          return Padding(
            padding: EdgeInsetsDirectional.only(
              start: index == 0 ? 0 : 2,
              end: 2,
            ),
            child: _DatabaseViewListItem(
              tabBar: tabBar,
              isSelected: currentView.viewId == tabBar.viewId,
            ),
          );
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: children),
        );
      },
    );
  }
}

class _DatabaseViewListItem extends StatefulWidget {
  const _DatabaseViewListItem({
    required this.tabBar,
    required this.isSelected,
  });

  final DatabaseTabBar tabBar;
  final bool isSelected;

  @override
  State<_DatabaseViewListItem> createState() => _DatabaseViewListItemState();
}

class _DatabaseViewListItemState extends State<_DatabaseViewListItem> {
  late final MaterialStatesController statesController;

  @override
  void initState() {
    super.initState();
    statesController = MaterialStatesController(
      <MaterialState>{if (widget.isSelected) MaterialState.selected},
    );
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      statesController.update(MaterialState.selected, widget.isSelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      statesController: statesController,
      style: ButtonStyle(
        padding: const MaterialStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        ),
        maximumSize: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Size(150, 48);
          }
          return const Size(120, 48);
        }),
        minimumSize: const MaterialStatePropertyAll(Size(48, 0)),
        shape: const MaterialStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0x0F212729);
          }
          return Colors.transparent;
        }),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return Theme.of(context).colorScheme.secondary;
        }),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewIconButton(context, widget.tabBar.view),
          const HSpace(6),
          Flexible(
            child: FlowyText(
              widget.tabBar.view.name,
              fontSize: 14,
              fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.w400,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onPressed: () {
        if (!widget.isSelected) {
          context
              .read<DatabaseTabBarBloc>()
              .add(DatabaseTabBarEvent.selectView(widget.tabBar.viewId));
        }
      },
    );
  }

  Widget _buildViewIconButton(BuildContext context, ViewPB view) {
    return view.icon.value.isNotEmpty
        ? EmojiText(
            emoji: view.icon.value,
            fontSize: 16.0,
          )
        : SizedBox.square(
            dimension: 16.0,
            child: view.defaultIcon(),
          );
  }
}
