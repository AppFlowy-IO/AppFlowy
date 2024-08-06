import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/_extension.dart';
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
  String spaceName = LocaleKeys.space_defaultSpaceName.tr();
  String? spaceIcon = builtInSpaceIcons.first;
  String? spaceIconColor = builtInSpaceColors.first;
  SpacePermission spacePermission = SpacePermission.publicToAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      width: 524,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText(
            LocaleKeys.space_createNewSpace.tr(),
            fontSize: 18.0,
            figmaLineHeight: 24.0,
          ),
          const VSpace(2.0),
          FlowyText(
            LocaleKeys.space_createSpaceDescription.tr(),
            fontSize: 14.0,
            fontWeight: FontWeight.w300,
            color: Theme.of(context).hintColor,
            figmaLineHeight: 18.0,
            maxLines: 2,
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
          _SpaceNameTextField(
            onChanged: (value) => spaceName = value,
            onSubmitted: (value) {
              spaceName = value;
              _createSpace();
            },
          ),
          const VSpace(20.0),
          SpacePermissionSwitch(
            onPermissionChanged: (value) => spacePermission = value,
          ),
          const VSpace(20.0),
          SpaceCancelOrConfirmButton(
            confirmButtonName: LocaleKeys.button_create.tr(),
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () => _createSpace(),
          ),
        ],
      ),
    );
  }

  void _createSpace() {
    context.read<SpaceBloc>().add(
          SpaceEvent.create(
            name: spaceName,
            // fixme: space issue
            icon: spaceIcon!,
            iconColor: spaceIconColor!,
            permission: spacePermission,
            createNewPageByDefault: true,
          ),
        );

    Navigator.of(context).pop();
  }
}

class _SpaceNameTextField extends StatelessWidget {
  const _SpaceNameTextField({
    required this.onChanged,
    required this.onSubmitted,
  });

  final void Function(String name) onChanged;
  final void Function(String name) onSubmitted;

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
          figmaLineHeight: 18.0,
        ),
        const VSpace(6.0),
        SizedBox(
          height: 40,
          child: FlowyTextField(
            hintText: LocaleKeys.space_spaceNamePlaceholder.tr(),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            enableBorderColor: context.enableBorderColor,
          ),
        ),
      ],
    );
  }
}
