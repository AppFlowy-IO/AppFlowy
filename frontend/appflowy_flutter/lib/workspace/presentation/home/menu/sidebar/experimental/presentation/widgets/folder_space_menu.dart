import 'dart:convert';
import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/create_space_popup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/manage_space_popup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_more_popup.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderSpaceMenu extends StatefulWidget {
  const FolderSpaceMenu({
    super.key,
    required this.space,
    required this.onAdded,
    required this.onCreateNewSpace,
    required this.onCollapseAllPages,
    required this.isExpanded,
  });

  final FolderViewPB space;
  final void Function(ViewLayoutPB layout) onAdded;
  final VoidCallback onCreateNewSpace;
  final VoidCallback onCollapseAllPages;
  final bool isExpanded;

  @override
  State<FolderSpaceMenu> createState() => _FolderSpaceMenuState();
}

class _FolderSpaceMenuState extends State<FolderSpaceMenu> {
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
      builder: (context, onHover, child) {
        return MouseRegion(
          onEnter: (_) => isHovered.value = true,
          onExit: (_) => isHovered.value = false,
          child: GestureDetector(
            onTap: () => context
                .read<SpaceBloc>()
                .add(SpaceEvent.expand(widget.space, !widget.isExpanded)),
            child: _buildSpaceName(onHover),
          ),
        );
      },
    );
  }

  Widget _buildSpaceName(bool isHovered) {
    return Container(
      height: HomeSizes.workspaceSectionHeight,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        color: isHovered ? Theme.of(context).colorScheme.secondary : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ValueListenableBuilder(
            valueListenable: onEditing,
            builder: (context, onEditing, child) => Positioned(
              left: 3,
              top: 3,
              bottom: 3,
              right: isHovered || onEditing ? 88 : 0,
              child: _FolderSpacePopup(
                showCreateButton: true,
                child: _buildChild(isHovered),
              ),
            ),
          ),
          Positioned(
            right: 4,
            child: _buildRightIcon(isHovered),
          ),
        ],
      ),
    );
  }

  Widget _buildChild(bool isHovered) {
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
        isHovered: isHovered,
      ),
    );
  }

  Widget _buildRightIcon(bool isHovered) {
    return ValueListenableBuilder(
      valueListenable: onEditing,
      builder: (context, onEditing, child) => Opacity(
        opacity: isHovered || onEditing ? 1 : 0,
        child: Row(
          children: [
            SpaceMorePopup(
              space: widget.space,
              onEditing: (value) => this.onEditing.value = value,
              onAction: _onAction,
              isHovered: isHovered,
            ),
            const HSpace(8.0),
            FlowyTooltip(
              message: LocaleKeys.sideBar_addAPage.tr(),
              child: ViewAddButton(
                parentViewId: widget.space.viewId,
                onEditing: (_) {},
                onSelected: (
                  pluginBuilder,
                  name,
                  initialDataBytes,
                  openAfterCreated,
                  createNewView,
                ) {
                  if (pluginBuilder.layoutType == ViewLayoutPB.Document) {
                    name = '';
                  }
                  if (createNewView) {
                    widget.onAdded(pluginBuilder.layoutType!);
                  }
                },
                isHovered: isHovered,
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
        if (data is SelectedEmojiIconResult) {
          if (data.type == FlowyIconType.icon) {
            try {
              final iconsData = IconsData.fromJson(jsonDecode(data.emoji));
              context.read<SpaceBloc>().add(
                    SpaceEvent.changeIcon(
                      icon: '${iconsData.groupName}/${iconsData.iconName}',
                      iconColor: iconsData.color,
                    ),
                  );
            } on FormatException catch (e) {
              context
                  .read<SpaceBloc>()
                  .add(const SpaceEvent.changeIcon(icon: ''));
              Log.warn('SidebarSpaceHeader changeIcon error:$e');
            }
          }
        }
        break;
      case SpaceMoreActionType.manage:
        _showManageSpaceDialog(context);
        break;
      case SpaceMoreActionType.createSpace:
        widget.onCreateNewSpace();
        break;
      case SpaceMoreActionType.collapseAllPages:
        widget.onCollapseAllPages();
        break;
      case SpaceMoreActionType.delete:
        _showDeleteSpaceDialog(context);
        break;
      case SpaceMoreActionType.duplicate:
        context.read<SpaceBloc>().add(
              SpaceEvent.duplicate(space: widget.space),
            );
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
        context.read<SpaceBloc>().add(
              SpaceEvent.rename(
                space: widget.space,
                name: name,
              ),
            );
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

class _FolderSpacePopup extends StatelessWidget {
  const _FolderSpacePopup({
    this.height,
    this.useIntrinsicWidth = true,
    this.expand = false,
    required this.showCreateButton,
    required this.child,
  });

  final bool showCreateButton;
  final bool useIntrinsicWidth;
  final bool expand;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? HomeSizes.workspaceSectionHeight,
      child: AppFlowyPopover(
        constraints: const BoxConstraints(maxWidth: 260),
        direction: PopoverDirection.bottomWithLeftAligned,
        clickHandler: PopoverClickHandler.gestureDetector,
        offset: const Offset(0, 4),
        popupBuilder: (_) => BlocProvider.value(
          value: context.read<SpaceBloc>(),
          child: _FolderSwitchSpaceMenu(
            showCreateButton: showCreateButton,
          ),
        ),
        child: FlowyButton(
          useIntrinsicWidth: useIntrinsicWidth,
          expand: expand,
          margin: const EdgeInsets.only(left: 3.0, right: 4.0),
          iconPadding: 10.0,
          text: child,
        ),
      ),
    );
  }
}

class _FolderSwitchSpaceMenu extends StatelessWidget {
  const _FolderSwitchSpaceMenu({
    required this.showCreateButton,
  });

  final bool showCreateButton;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        final spaces = state.spaces;
        if (spaces.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentSpace = state.currentSpace ?? spaces.first;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSpace(4.0),
            for (final space in spaces)
              SizedBox(
                height: HomeSpaceViewSizes.viewHeight,
                child: _FolderSpaceMenuItem(
                  space: space,
                  isSelected: currentSpace.viewId == space.viewId,
                ),
              ),
            if (showCreateButton) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: FlowyDivider(),
              ),
              const SizedBox(
                height: HomeSpaceViewSizes.viewHeight,
                child: _CreateSpaceButton(),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FolderSpaceMenuItem extends StatelessWidget {
  const _FolderSpaceMenuItem({
    required this.space,
    required this.isSelected,
  });

  final FolderViewPB space;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: Row(
        children: [
          Flexible(
            child: FlowyText.regular(
              space.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(6.0),
          if (space.isPrivate)
            FlowyTooltip(
              message: LocaleKeys.space_privatePermissionDescription.tr(),
              child: const FlowySvg(
                FlowySvgs.space_lock_s,
              ),
            ),
        ],
      ),
      iconPadding: 10,
      leftIcon: SpaceIcon(
        dimension: 20,
        space: space,
        svgSize: 12.0,
        cornerRadius: 6.0,
      ),
      leftIconSize: const Size.square(20),
      rightIcon: isSelected
          ? const FlowySvg(
              FlowySvgs.workspace_selected_s,
              blendMode: null,
            )
          : null,
      onTap: () {
        context.read<SpaceBloc>().add(
              SpaceEvent.switchCurrentSpace(spaceId: space.viewId),
            );
        PopoverContainer.of(context).close();
      },
    );
  }
}

class _CreateSpaceButton extends StatelessWidget {
  const _CreateSpaceButton();

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: FlowyText.regular(LocaleKeys.space_createNewSpace.tr()),
      iconPadding: 10,
      leftIcon: const FlowySvg(
        FlowySvgs.space_add_s,
      ),
      onTap: () {
        PopoverContainer.of(context).close();
        _showCreateSpaceDialog(context);
      },
    );
  }

  void _showCreateSpaceDialog(BuildContext context) {
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
            child: const CreateSpacePopup(),
          ),
        );
      },
    );
  }
}
