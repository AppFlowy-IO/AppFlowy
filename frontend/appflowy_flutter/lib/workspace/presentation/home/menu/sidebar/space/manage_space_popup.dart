import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageSpacePopup extends StatefulWidget {
  const ManageSpacePopup({super.key});

  @override
  State<ManageSpacePopup> createState() => _ManageSpacePopupState();
}

class _ManageSpacePopupState extends State<ManageSpacePopup> {
  String? spaceName;
  String? spaceIcon;
  String? spaceIconColor;
  SpacePermission? spacePermission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText(
            LocaleKeys.space_manage.tr(),
            fontSize: 18.0,
          ),
          const VSpace(16.0),
          _SpaceNameTextField(
            onNameChanged: (name) => spaceName = name,
            onIconChanged: (icon, color) {
              spaceIcon = icon;
              spaceIconColor = color;
            },
          ),
          const VSpace(16.0),
          SpacePermissionSwitch(
            spacePermission:
                context.read<SpaceBloc>().state.currentSpace?.spacePermission,
            onPermissionChanged: (value) => spacePermission = value,
          ),
          const VSpace(16.0),
          SpaceCancelOrConfirmButton(
            confirmButtonName: LocaleKeys.button_save.tr(),
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () {
              context.read<SpaceBloc>().add(
                    SpaceEvent.update(
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
  const _SpaceNameTextField({
    required this.onNameChanged,
    required this.onIconChanged,
  });

  final void Function(String name) onNameChanged;
  final void Function(String? icon, String? color) onIconChanged;

  @override
  Widget build(BuildContext context) {
    final space = context.read<SpaceBloc>().state.currentSpace;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.regular(
          LocaleKeys.space_spaceName.tr(),
          fontSize: 14.0,
          color: Theme.of(context).hintColor,
        ),
        const VSpace(8.0),
        SizedBox(
          height: 40,
          child: Row(
            children: [
              SizedBox.square(
                dimension: 40,
                child: SpaceIconPopup(
                  space: space,
                  cornerRadius: 12,
                  icon: space?.spaceIcon,
                  iconColor: space?.spaceIconColor,
                  onIconChanged: onIconChanged,
                ),
              ),
              const HSpace(12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: FlowyTextField(
                    text: space?.name,
                    onChanged: onNameChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
