import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/manage_space_popup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/sidebar_space_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_more_popup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarSpaceHeader extends StatefulWidget {
  const SidebarSpaceHeader({
    super.key,
    required this.space,
    required this.onAdded,
    required this.onCreateNewSpace,
    required this.onCollapseAllPages,
    required this.isExpanded,
  });

  final ViewPB space;
  final VoidCallback onAdded;
  final VoidCallback onCreateNewSpace;
  final VoidCallback onCollapseAllPages;
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
                  rightIcon: const HSpace(60.0),
                ),
              ),
              Positioned(
                right: 4,
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
        SpaceIcon(
          dimension: 20,
          space: widget.space,
          cornerRadius: 6.0,
        ),
        const HSpace(10),
        Flexible(
          child: FlowyText.medium(
            widget.space.name,
            lineHeight: 1.15,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
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
              onAction: _onAction,
            ),
            const HSpace(8.0),
            FlowyIconButton(
              width: 24,
              tooltipText: LocaleKeys.sideBar_addAPage.tr(),
              iconPadding: const EdgeInsets.all(4.0),
              icon: const FlowySvg(FlowySvgs.view_item_add_s),
              onPressed: widget.onAdded,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(SpaceMoreActionType type, dynamic data) async {
    switch (type) {
      case SpaceMoreActionType.rename:
        await _showRenameDialog();
        break;
      case SpaceMoreActionType.changeIcon:
        final (String icon, String iconColor) = data;
        context.read<SpaceBloc>().add(SpaceEvent.changeIcon(icon, iconColor));
        break;
      case SpaceMoreActionType.manage:
        _showManageSpaceDialog(context);
        break;
      case SpaceMoreActionType.addNewSpace:
        widget.onCreateNewSpace();
        break;
      case SpaceMoreActionType.collapseAllPages:
        widget.onCollapseAllPages();
        break;
      case SpaceMoreActionType.delete:
        _showDeleteSpaceDialog(context);
        break;
      case SpaceMoreActionType.divider:
        break;
    }
  }

  Future<void> _showRenameDialog() async {
    await NavigatorTextFieldDialog(
      title: LocaleKeys.space_rename.tr(),
      value: widget.space.name,
      autoSelectAllText: true,
      hintText: LocaleKeys.space_spaceName.tr(),
      onConfirm: (name, _) {
        context.read<SpaceBloc>().add(SpaceEvent.rename(widget.space, name));
      },
    ).show(context);
  }

  void _showManageSpaceDialog(BuildContext context) {
    final spaceBloc = context.read<SpaceBloc>();
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: BlocProvider.value(
            value: spaceBloc,
            child: const ManageSpacePopup(),
          ),
        );
      },
    );
  }

  void _showDeleteSpaceDialog(BuildContext context) {
    final spaceBloc = context.read<SpaceBloc>();
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: BlocProvider.value(
            value: spaceBloc,
            child: const SizedBox(width: 440, child: DeleteSpacePopup()),
          ),
        );
      },
    );
  }
}
