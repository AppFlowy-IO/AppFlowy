import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/space/space_menu_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/workspaces/create_workspace_menu.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/util/navigator_context_extension.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'manage_space_widget.dart';

class MobileSpaceMenu extends StatelessWidget {
  const MobileSpaceMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VSpace(4.0),
              for (final space in state.spaces)
                SizedBox(
                  height: 52,
                  child: _SidebarSpaceMenuItem(
                    space: space,
                    isSelected: state.currentSpace?.id == space.id,
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(
                  height: 0.5,
                ),
              ),
              const SizedBox(
                height: 52,
                child: _CreateSpaceButton(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarSpaceMenuItem extends StatelessWidget {
  const _SidebarSpaceMenuItem({
    required this.space,
    required this.isSelected,
  });

  final ViewPB space;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: Row(
        children: [
          FlowyText.medium(
            space.name,
            fontSize: 16.0,
          ),
          const HSpace(6.0),
          if (space.spacePermission == SpacePermission.private)
            const FlowySvg(
              FlowySvgs.space_lock_s,
              size: Size.square(12),
            ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      iconPadding: 10,
      leftIcon: SpaceIcon(
        dimension: 24,
        space: space,
        svgSize: 14,
        textDimension: 18.0,
        cornerRadius: 6.0,
      ),
      leftIconSize: const Size.square(24),
      rightIcon: _SpaceMenuItemTrailing(
        space: space,
        currentSpace: context.read<SpaceBloc>().state.currentSpace,
      ),
      onTap: () {
        context.read<SpaceBloc>().add(SpaceEvent.open(space));
        Navigator.of(context).pop();
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
      leftIcon: const Padding(
        padding: EdgeInsets.all(2.0),
        child: FlowySvg(
          FlowySvgs.space_add_s,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      leftIconSize: const Size.square(24),
      onTap: () => _showCreateSpaceDialog(context),
    );
  }

  void _showCreateSpaceDialog(BuildContext context) {
    showMobileBottomSheet(
      context,
      showHeader: true,
      title: 'Create space',
      showCloseButton: true,
      showDivider: false,
      showDoneButton: true,
      enableScrollable: true,
      showDragHandle: true,
      bottomSheetPadding: context.bottomSheetPadding(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      builder: (bottomSheetContext) => const ManageSpaceWidget(),
    );
  }
}

class _SpaceMenuItemTrailing extends StatelessWidget {
  const _SpaceMenuItemTrailing({
    required this.space,
    this.currentSpace,
  });

  final ViewPB space;
  final ViewPB? currentSpace;

  @override
  Widget build(BuildContext context) {
    const iconSize = Size.square(20);
    return Row(
      children: [
        const HSpace(12.0),
        // show the check icon if the space is the current space
        if (space.id == currentSpace?.id)
          const FlowySvg(
            FlowySvgs.m_blue_check_s,
            size: iconSize,
            blendMode: null,
          ),
        const HSpace(15.0),
        // more options button
        AnimatedGestureDetector(
          onTapUp: () => _showMoreOptions(context),
          child: const FlowySvg(
            FlowySvgs.workspace_three_dots_s,
            size: iconSize,
          ),
        ),
        const HSpace(8.0),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    final actions = [
      // SpaceMoreActionType.rename,
      SpaceMoreActionType.duplicate,
      SpaceMoreActionType.manage,
      SpaceMoreActionType.delete,
    ];

    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (bottomSheetContext) {
        return SpaceMenuMoreOptions(
          actions: actions,
          onAction: (action) => _onActions(context, bottomSheetContext, action),
        );
      },
    );
  }

  void _onActions(
    BuildContext context,
    BuildContext bottomSheetContext,
    SpaceMoreActionType action,
  ) {
    Log.info('execute action in space menu bottom sheet: $action');

    switch (action) {
      case SpaceMoreActionType.rename:
        _showRenameSpaceBottomSheet(context);
        break;
      case SpaceMoreActionType.duplicate:
        _duplicateSpace(context, bottomSheetContext);
        break;
      case SpaceMoreActionType.manage:
        break;
      case SpaceMoreActionType.delete:
        _deleteSpace(context, bottomSheetContext);
        break;
      default:
        assert(false, 'Unsupported action: $action');
        break;
    }
  }

  void _duplicateSpace(BuildContext context, BuildContext bottomSheetContext) {
    Log.info('duplicate the space: ${space.name}');

    context.read<SpaceBloc>().add(const SpaceEvent.duplicate());

    showToastNotification(
      context,
      message: LocaleKeys.space_success_duplicateSpace.tr(),
    );

    Navigator.of(bottomSheetContext).pop();
  }

  void _showRenameSpaceBottomSheet(BuildContext context) {
    showMobileBottomSheet(
      context,
      showHeader: true,
      title: LocaleKeys.workspace_renameWorkspace.tr(),
      showCloseButton: true,
      showDragHandle: true,
      showDivider: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      builder: (bottomSheetContext) {
        return EditWorkspaceNameBottomSheet(
          type: EditWorkspaceNameType.edit,
          workspaceName: space.name,
          onSubmitted: (name) {
            // rename the workspace
            Log.info('rename the space: $name');
            bottomSheetContext.popToHome();

            context.read<SpaceBloc>().add(SpaceEvent.rename(space, name));
          },
        );
      },
    );
  }

  void _deleteSpace(
    BuildContext context,
    BuildContext bottomSheetContext,
  ) {
    Navigator.of(bottomSheetContext).pop();

    _showConfirmDialog(
      context,
      '${LocaleKeys.space_delete.tr()}: ${space.name}',
      LocaleKeys.space_deleteConfirmationDescription.tr(),
      LocaleKeys.button_delete.tr(),
      (_) async {
        context.read<SpaceBloc>().add(SpaceEvent.delete(space));

        showToastNotification(
          context,
          message: LocaleKeys.space_success_deleteSpace.tr(),
        );

        context.popToHome();
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
    String rightButtonText,
    void Function(BuildContext context)? onRightButtonPressed,
  ) {
    showFlowyCupertinoConfirmDialog(
      title: title,
      content: FlowyText(
        content,
        fontSize: 14,
        color: Theme.of(context).hintColor,
        maxLines: 10,
      ),
      leftButton: FlowyText(
        LocaleKeys.button_cancel.tr(),
        fontSize: 17.0,
        figmaLineHeight: 24.0,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF007AFF),
      ),
      rightButton: FlowyText(
        rightButtonText,
        fontSize: 17.0,
        figmaLineHeight: 24.0,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFFE0220),
      ),
      onRightButtonPressed: onRightButtonPressed,
    );
  }
}
