import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class CreateSpacePopup extends StatelessWidget {
  const CreateSpacePopup({super.key});

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
          const _SpaceNameTextField(),
          const VSpace(16.0),
          const _SpacePermissionSwitch(),
          const VSpace(16.0),
          const _CancelOrCreateButton(),
        ],
      ),
    );
  }
}

class _SpaceIcon extends StatelessWidget {
  const _SpaceIcon({super.key});

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
  const _SpaceNameTextField({super.key});

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
          onChanged: (value) {},
        ),
      ],
    );
  }
}

class _SpacePermissionSwitch extends StatelessWidget {
  const _SpacePermissionSwitch({super.key});

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
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0x1E14171B)),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const _SpacePermissionButton(
            permission: SpacePermission.publicToAll,
          ),
        ),
      ],
    );
  }
}

class _SpacePermissionButton extends StatelessWidget {
  const _SpacePermissionButton({super.key, required this.permission});

  final SpacePermission permission;

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
      // onTap: () {},
    );
  }
}

class _CancelOrCreateButton extends StatelessWidget {
  const _CancelOrCreateButton({super.key});

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
            onTap: () {
              Navigator.of(context).pop();
            },
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
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
