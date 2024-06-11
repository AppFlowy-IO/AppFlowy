import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateSpacePopup extends StatefulWidget {
  const CreateSpacePopup({super.key});

  @override
  State<CreateSpacePopup> createState() => _CreateSpacePopupState();
}

class _CreateSpacePopupState extends State<CreateSpacePopup> {
  String spaceName = '';
  String spaceIcon = '';
  SpacePermission spacePermission = SpacePermission.publicToAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlowyText(
            'Create new space',
            fontSize: 18.0,
          ),
          const VSpace(4.0),
          FlowyText.regular(
            'Separate your tabs for life, work, projects and more',
            fontSize: 14.0,
            color: Theme.of(context).hintColor,
          ),
          const VSpace(16.0),
          const _SpaceIcon(),
          const VSpace(8.0),
          _SpaceNameTextField(onChanged: (value) => spaceName = value),
          const VSpace(16.0),
          _SpacePermissionSwitch(
            onPermissionChanged: (value) => spacePermission = value,
          ),
          const VSpace(16.0),
          _CancelOrCreateButton(
            onCancel: () => Navigator.of(context).pop(),
            onCreate: () {
              if (spaceName.isEmpty) {
                // todo: show error
                return;
              }

              context.read<SpaceBloc>().add(
                    SpaceEvent.create(
                      name: spaceName,
                      icon: spaceIcon,
                      permission: spacePermission,
                    ),
                  );

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _SpaceIcon extends StatelessWidget {
  const _SpaceIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 56.0,
      child: FlowySvg(
        FlowySvgs.space_icon_s,
        blendMode: null,
      ),
    );
  }
}

class _SpaceNameTextField extends StatelessWidget {
  const _SpaceNameTextField({required this.onChanged});

  final void Function(String name) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.regular(
          'Space name',
          fontSize: 14.0,
          color: Theme.of(context).hintColor,
        ),
        const VSpace(6.0),
        FlowyTextField(
          hintText: 'Untitled space',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SpacePermissionSwitch extends StatefulWidget {
  const _SpacePermissionSwitch({required this.onPermissionChanged});

  final void Function(SpacePermission permission) onPermissionChanged;

  @override
  State<_SpacePermissionSwitch> createState() => _SpacePermissionSwitchState();
}

class _SpacePermissionSwitchState extends State<_SpacePermissionSwitch> {
  SpacePermission spacePermission = SpacePermission.publicToAll;
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.regular(
          'Permission',
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
                side: const BorderSide(color: Color(0x1E14171B)),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _SpacePermissionButton(
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
          _SpacePermissionButton(
            permission: SpacePermission.publicToAll,
            onTap: () => _onPermissionChanged(SpacePermission.publicToAll),
          ),
          _SpacePermissionButton(
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

class _SpacePermissionButton extends StatelessWidget {
  const _SpacePermissionButton({required this.permission, this.onTap});

  final SpacePermission permission;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (title, desc, icon) = switch (permission) {
      SpacePermission.publicToAll => (
          'Public',
          'All workspace members with full access',
          FlowySvgs.space_permission_public_s
        ),
      SpacePermission.private => (
          'Private',
          'Only you can access this space',
          FlowySvgs.space_permission_public_s
        ),
    };

    return FlowyButton(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      radius: BorderRadius.circular(10),
      iconPadding: 16.0,
      leftIcon: FlowySvg(icon),
      rightIcon: const FlowySvg(FlowySvgs.space_permission_dropdown_s),
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

class _CancelOrCreateButton extends StatelessWidget {
  const _CancelOrCreateButton({required this.onCancel, required this.onCreate});

  final VoidCallback onCancel;
  final VoidCallback onCreate;

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
            text: const FlowyText.regular('Cancel'),
            onTap: onCancel,
          ),
        ),
        const HSpace(12.0),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: FlowyButton(
            useIntrinsicWidth: true,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
            text: FlowyText.regular(
              'Create',
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onTap: onCreate,
          ),
        ),
      ],
    );
  }
}
