import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/grid_bloc.dart';
import 'package:app_flowy/plugins/grid/application/setting/setting_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'grid_property.dart';
import 'grid_setting.dart';

class SettingButton extends StatefulWidget {
  const SettingButton({Key? key}) : super(key: key);

  @override
  State<SettingButton> createState() => _SettingButtonState();
}

class _SettingButtonState extends State<SettingButton> {
  late PopoverController popoverController;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GridBloc, GridState, GridSettingContext>(
      selector: (state) {
        final fieldController =
            context.read<GridBloc>().gridController.fieldController;
        return GridSettingContext(
          gridId: state.gridId,
          fieldController: fieldController,
        );
      },
      builder: (context, settingContext) {
        return AppFlowyPopover(
          controller: popoverController,
          constraints: BoxConstraints.loose(const Size(260, 400)),
          direction: PopoverDirection.leftWithTopAligned,
          offset: const Offset(0, 10),
          margin: const EdgeInsets.all(6),
          triggerActions: PopoverTriggerFlags.none,
          child: FlowyTextButton(
            LocaleKeys.settings_title.tr(),
            fontSize: 13,
            fillColor: Colors.transparent,
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            onPressed: () {
              popoverController.show();
            },
          ),
          popupBuilder: (BuildContext context) {
            return _GridSettingListPopover(settingContext: settingContext);
          },
        );
      },
    );
  }
}

class _GridSettingListPopover extends StatefulWidget {
  final GridSettingContext settingContext;

  const _GridSettingListPopover({Key? key, required this.settingContext})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _GridSettingListPopoverState();
}

class _GridSettingListPopoverState extends State<_GridSettingListPopover> {
  GridSettingAction? _action;

  @override
  Widget build(BuildContext context) {
    if (_action == GridSettingAction.showProperties) {
      return GridPropertyList(
        gridId: widget.settingContext.gridId,
        fieldController: widget.settingContext.fieldController,
      );
    }

    return GridSettingList(
      settingContext: widget.settingContext,
      onAction: (action, settingContext) {
        setState(() {
          _action = action;
        });
      },
    );
  }
}
