import 'dart:io';

import 'package:flutter/material.dart' hide Icon;

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/manage_space_popup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_more_popup.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
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
  final void Function(ViewLayoutPB layout) onAdded;
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
    return ValueListenableBuilder(
      valueListenable: isHovered,
      builder: (context, isHovered, child) {
        final style = HoverStyle(
          hoverColor: isHovered
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
        );
        return GestureDetector(
          onTap: () => context
              .read<SpaceBloc>()
              .add(SpaceEvent.expand(widget.space, !widget.isExpanded)),
          child: FlowyHoverContainer(
            style: style,
            applyStyle: isHovered,
            child: _buildSpaceName(),
          ),
        );
      },
    );
  }

  Widget _buildSpaceName() {
    return SizedBox(
      height: HomeSizes.workspaceSectionHeight,
      child: MouseRegion(
        onEnter: (_) => isHovered.value = true,
        onExit: (_) => isHovered.value = false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: onEditing,
              builder: (context, onEditing, child) => Positioned(
                left: 3,
                top: 3,
                bottom: 3,
                right: isHovered.value || onEditing ? 88 : 0,
                child: SpacePopup(
                  showCreateButton: true,
                  child: _buildChild(),
                ),
              ),
            ),
            Positioned(
              right: 4,
              child: _buildRightIcon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChild() {
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: '${LocaleKeys.space_quicklySwitch.tr()}\n',
          style: context.tooltipTextStyle(),
        ),
        TextSpan(
          text: Platform.isMacOS ? '⌘+O' : 'Ctrl+O',
          style: context
              .tooltipTextStyle()
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
    return FlowyTooltip(
      richMessage: textSpan,
      child: CurrentSpace(
        space: widget.space,
      ),
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
            FlowyTooltip(
              message: LocaleKeys.sideBar_addAPage.tr(),
              child: ViewAddButton(
                parentViewId: widget.space.id,
                onEditing: (_) {},
                onSelected: (
                  pluginBuilder,
                  name,
                  initialDataBytes,
                  openAfterCreated,
                  createNewView,
                ) {
                  if (createNewView) {
                    widget.onAdded(pluginBuilder.layoutType!);
                  }
                },
              ),
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
        final (IconGroup? group, Icon? icon, String? iconColor) = data;

        final groupName = group?.name;
        final iconName = icon?.name;
        final name = groupName != null && iconName != null
            ? '$groupName/$iconName'
            : null;
        context.read<SpaceBloc>().add(
              SpaceEvent.changeIcon(
                name,
                iconColor,
              ),
            );
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
      case SpaceMoreActionType.duplicate:
        context.read<SpaceBloc>().add(const SpaceEvent.duplicate());
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
    final space = spaceBloc.state.currentSpace;
    final name = space != null ? space.name : '';
    showConfirmDeletionDialog(
      context: context,
      name: name,
      description: LocaleKeys.space_deleteConfirmationDescription.tr(),
      onConfirm: () {
        context.read<SpaceBloc>().add(const SpaceEvent.delete(null));
      },
    );
  }
}
