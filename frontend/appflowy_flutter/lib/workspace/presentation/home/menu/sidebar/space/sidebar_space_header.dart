import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/sidebar_space_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_more_popup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarSpaceHeader extends StatefulWidget {
  const SidebarSpaceHeader({
    super.key,
    required this.space,
    required this.onPressed,
    required this.onAdded,
    required this.onTapMore,
    required this.isExpanded,
  });

  final ViewPB space;
  final VoidCallback onPressed;
  final VoidCallback onAdded;
  final VoidCallback onTapMore;
  final bool isExpanded;

  @override
  State<SidebarSpaceHeader> createState() => _SidebarSpaceHeaderState();
}

class _SidebarSpaceHeaderState extends State<SidebarSpaceHeader> {
  final isHovered = ValueNotifier(false);
  final onEditing = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();
    onEditing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: const BoxConstraints(maxWidth: 252),
      direction: PopoverDirection.bottomWithLeftAligned,
      clickHandler: PopoverClickHandler.gestureDetector,
      offset: const Offset(0, 4),
      popupBuilder: (_) => BlocProvider.value(
        value: context.read<SpaceBloc>(),
        child: const SidebarSpaceMenu(),
      ),
      child: SizedBox(
        height: HomeSizes.workspaceSectionHeight,
        child: MouseRegion(
          onEnter: (_) => isHovered.value = true,
          onExit: (_) => isHovered.value = false,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: HomeSizes.workspaceSectionHeight,
                child: FlowyButton(
                  margin: const EdgeInsets.only(left: 6.0, right: 4.0),
                  // rightIcon: _buildRightIcon(),
                  iconPadding: 10.0,
                  text: _buildChild(),
                ),
              ),
              Positioned(
                right: 0,
                child: _buildRightIcon(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChild() {
    return Row(
      children: [
        SizedBox.square(dimension: 20, child: widget.space.spaceIcon),
        const HSpace(10),
        FlowyText.medium(
          widget.space.name,
          lineHeight: 1.15,
          fontSize: 14.0,
        ),
        const HSpace(4.0),
        FlowySvg(
          widget.isExpanded
              ? FlowySvgs.workspace_drop_down_menu_show_s
              : FlowySvgs.workspace_drop_down_menu_hide_s,
        ),
      ],
    );
  }

  Widget _buildRightIcon() {
    return ValueListenableBuilder(
      valueListenable: onEditing,
      builder: (context, onEditing, child) => ValueListenableBuilder(
        valueListenable: isHovered,
        builder: (context, onHover, child) =>
            Opacity(opacity: onHover || onEditing ? 1 : 0, child: child),
        child: Row(
          children: [
            SpaceMorePopup(
              space: widget.space,
              onEditing: (value) => this.onEditing.value = value,
              onAction: (_, __) {},
            ),
            const HSpace(8.0),
            FlowyIconButton(
              width: 24,
              iconPadding: const EdgeInsets.all(4.0),
              icon: const FlowySvg(FlowySvgs.view_item_add_s),
              onPressed: widget.onAdded,
            ),
          ],
        ),
      ),
    );
  }
}
