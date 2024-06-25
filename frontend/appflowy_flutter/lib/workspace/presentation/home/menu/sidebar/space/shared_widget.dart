import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/sidebar_space_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpacePermissionSwitch extends StatefulWidget {
  const SpacePermissionSwitch({
    super.key,
    required this.onPermissionChanged,
    this.spacePermission,
    this.showArrow = false,
  });

  final SpacePermission? spacePermission;
  final void Function(SpacePermission permission) onPermissionChanged;
  final bool showArrow;

  @override
  State<SpacePermissionSwitch> createState() => _SpacePermissionSwitchState();
}

class _SpacePermissionSwitchState extends State<SpacePermissionSwitch> {
  late SpacePermission spacePermission =
      widget.spacePermission ?? SpacePermission.publicToAll;
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.regular(
          LocaleKeys.space_permission.tr(),
          fontSize: 14.0,
          color: Theme.of(context).hintColor,
        ),
        const VSpace(6.0),
        AppFlowyPopover(
          controller: popoverController,
          direction: PopoverDirection.bottomWithCenterAligned,
          constraints: const BoxConstraints(maxWidth: 500),
          offset: const Offset(0, 4),
          margin: EdgeInsets.zero,
          decoration: FlowyDecoration.decoration(
            Theme.of(context).cardColor,
            Theme.of(context).colorScheme.shadow,
            borderRadius: 10,
          ),
          popupBuilder: (_) => _buildPermissionButtons(),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: SpacePermissionButton(
              showArrow: true,
              permission: spacePermission,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionButtons() {
    return SizedBox(
      width: 452,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpacePermissionButton(
            permission: SpacePermission.publicToAll,
            onTap: () => _onPermissionChanged(SpacePermission.publicToAll),
          ),
          SpacePermissionButton(
            permission: SpacePermission.private,
            onTap: () => _onPermissionChanged(SpacePermission.private),
          ),
        ],
      ),
    );
  }

  void _onPermissionChanged(SpacePermission permission) {
    widget.onPermissionChanged(permission);

    setState(() {
      spacePermission = permission;
    });

    popoverController.close();
  }
}

class SpacePermissionButton extends StatelessWidget {
  const SpacePermissionButton({
    super.key,
    required this.permission,
    this.onTap,
    this.showArrow = false,
  });

  final SpacePermission permission;
  final VoidCallback? onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final (title, desc, icon) = switch (permission) {
      SpacePermission.publicToAll => (
          LocaleKeys.space_publicPermission.tr(),
          LocaleKeys.space_publicPermissionDescription.tr(),
          FlowySvgs.space_permission_public_s
        ),
      SpacePermission.private => (
          LocaleKeys.space_privatePermission.tr(),
          LocaleKeys.space_privatePermissionDescription.tr(),
          FlowySvgs.space_permission_private_s
        ),
    };

    return FlowyButton(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      radius: BorderRadius.circular(10),
      iconPadding: 16.0,
      leftIcon: FlowySvg(icon),
      rightIcon: showArrow
          ? const FlowySvg(FlowySvgs.space_permission_dropdown_s)
          : null,
      text: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText.regular(title),
          const VSpace(4.0),
          FlowyText.regular(
            desc,
            fontSize: 12.0,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class SpaceCancelOrConfirmButton extends StatelessWidget {
  const SpaceCancelOrConfirmButton({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmButtonName,
    this.confirmButtonColor,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmButtonName;
  final Color? confirmButtonColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0x1E14171B)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: FlowyButton(
            useIntrinsicWidth: true,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
            text: FlowyText.regular(LocaleKeys.button_cancel.tr()),
            onTap: onCancel,
          ),
        ),
        const HSpace(12.0),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: confirmButtonColor ?? Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: FlowyButton(
            useIntrinsicWidth: true,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
            radius: BorderRadius.circular(8),
            text: FlowyText.regular(
              confirmButtonName,
              color: Colors.white,
            ),
            onTap: onConfirm,
          ),
        ),
      ],
    );
  }
}

class DeleteSpacePopup extends StatelessWidget {
  const DeleteSpacePopup({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.read<SpaceBloc>().state.currentSpace;
    final name = space != null ? space.name : '';
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlowyText(
                LocaleKeys.space_deleteConfirmation.tr() + name,
                fontSize: 14.0,
              ),
              const Spacer(),
              FlowyButton(
                useIntrinsicWidth: true,
                text: const FlowySvg(FlowySvgs.upgrade_close_s),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const VSpace(8.0),
          FlowyText.regular(
            LocaleKeys.space_deleteConfirmationDescription.tr(),
            fontSize: 12.0,
            color: Theme.of(context).hintColor,
            maxLines: 3,
            lineHeight: 1.4,
          ),
          const VSpace(20.0),
          SpaceCancelOrConfirmButton(
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () {
              context.read<SpaceBloc>().add(const SpaceEvent.delete(null));
              Navigator.of(context).pop();
            },
            confirmButtonName: LocaleKeys.space_delete.tr(),
            confirmButtonColor: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class SpacePopup extends StatelessWidget {
  const SpacePopup({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeSizes.workspaceSectionHeight,
      child: AppFlowyPopover(
        constraints: const BoxConstraints(maxWidth: 260),
        direction: PopoverDirection.bottomWithLeftAligned,
        clickHandler: PopoverClickHandler.gestureDetector,
        offset: const Offset(0, 4),
        popupBuilder: (_) => BlocProvider.value(
          value: context.read<SpaceBloc>(),
          child: const SidebarSpaceMenu(),
        ),
        child: FlowyButton(
          useIntrinsicWidth: true,
          margin: const EdgeInsets.only(left: 3.0, right: 4.0),
          iconPadding: 10.0,
          text: child,
        ),
      ),
    );
  }
}

class CurrentSpace extends StatelessWidget {
  const CurrentSpace({
    super.key,
    required this.space,
  });

  final ViewPB space;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SpaceIcon(
          dimension: 20,
          space: space,
          cornerRadius: 6.0,
        ),
        const HSpace(10),
        Flexible(
          child: FlowyText.medium(
            space.name,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const HSpace(4.0),
        const FlowySvg(
          FlowySvgs.workspace_drop_down_menu_show_s,
        ),
      ],
    );
  }
}

class SpacePages extends StatelessWidget {
  const SpacePages({
    super.key,
    required this.space,
    required this.isHovered,
    required this.isExpandedNotifier,
    required this.onSelected,
    this.rightIconsBuilder,
    this.disableSelectedStatus = false,
    this.onTertiarySelected,
  });

  final ViewPB space;
  final ValueNotifier<bool> isHovered;
  final PropertyValueNotifier<bool> isExpandedNotifier;
  final bool disableSelectedStatus;
  final ViewItemRightIconsBuilder? rightIconsBuilder;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected? onTertiarySelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ViewBloc(view: space)..add(const ViewEvent.initial()),
      child: BlocBuilder<ViewBloc, ViewState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: state.view.childViews
                .map(
                  (view) => ViewItem(
                    key: ValueKey('${space.id} ${view.id}'),
                    spaceType:
                        space.spacePermission == SpacePermission.publicToAll
                            ? FolderSpaceType.public
                            : FolderSpaceType.private,
                    isFirstChild: view.id == state.view.childViews.first.id,
                    view: view,
                    level: 0,
                    leftPadding: HomeSpaceViewSizes.leftPadding,
                    isFeedback: false,
                    isHovered: isHovered,
                    disableSelectedStatus: disableSelectedStatus,
                    isExpandedNotifier: isExpandedNotifier,
                    rightIconsBuilder: rightIconsBuilder,
                    onSelected: onSelected,
                    onTertiarySelected: onTertiarySelected,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
