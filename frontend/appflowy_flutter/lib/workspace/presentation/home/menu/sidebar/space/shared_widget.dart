import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
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
              color: Theme.of(context).colorScheme.onPrimary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText(
            LocaleKeys.space_deleteConfirmation.tr(),
            fontSize: 14.0,
          ),
          const VSpace(16.0),
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
          const VSpace(8.0),
        ],
      ),
    );
  }
}
