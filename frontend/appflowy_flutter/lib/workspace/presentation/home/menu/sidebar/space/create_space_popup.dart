import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
  String spaceIconColor = '';
  SpacePermission spacePermission = SpacePermission.publicToAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText(
            LocaleKeys.space_createNewSpace.tr(),
            fontSize: 18.0,
          ),
          const VSpace(4.0),
          FlowyText.regular(
            LocaleKeys.space_createSpaceDescription.tr(),
            fontSize: 14.0,
            color: Theme.of(context).hintColor,
          ),
          const VSpace(16.0),
          SizedBox.square(
            dimension: 56,
            child: SpaceIconPopup(
              onIconChanged: (icon, iconColor) {
                spaceIcon = icon;
                spaceIconColor = iconColor;
              },
            ),
          ),
          const VSpace(8.0),
          _SpaceNameTextField(onChanged: (value) => spaceName = value),
          const VSpace(16.0),
          SpacePermissionSwitch(
            onPermissionChanged: (value) => spacePermission = value,
          ),
          const VSpace(16.0),
          SpaceCancelOrConfirmButton(
            confirmButtonName: LocaleKeys.button_create.tr(),
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () {
              if (spaceName.isEmpty) {
                // todo: show error
                return;
              }

              context.read<SpaceBloc>().add(
                    SpaceEvent.create(
                      name: spaceName,
                      icon: spaceIcon,
                      iconColor: spaceIconColor,
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
          LocaleKeys.space_spaceName.tr(),
          fontSize: 14.0,
          color: Theme.of(context).hintColor,
        ),
        const VSpace(6.0),
        SizedBox(
          height: 40,
          child: FlowyTextField(
            hintText: 'Untitled space',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
