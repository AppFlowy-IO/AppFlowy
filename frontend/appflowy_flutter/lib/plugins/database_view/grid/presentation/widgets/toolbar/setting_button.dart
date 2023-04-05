import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/setting/setting_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../layout/sizes.dart';
import 'grid_property.dart';
import 'grid_setting.dart';

class SettingButton extends StatefulWidget {
  const SettingButton({Key? key}) : super(key: key);

  @override
  State<SettingButton> createState() => _SettingButtonState();
}

class _SettingButtonState extends State<SettingButton> {
  late PopoverController _popoverController;

  @override
  void initState() {
    _popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GridBloc, GridState, GridSettingContext>(
      selector: (state) {
        final fieldController =
            context.read<GridBloc>().databaseController.fieldController;
        return GridSettingContext(
          viewId: state.viewId,
          fieldController: fieldController,
        );
      },
      builder: (context, settingContext) {
        return SizedBox(
          height: 26,
          child: AppFlowyPopover(
            controller: _popoverController,
            constraints: BoxConstraints.loose(const Size(260, 400)),
            direction: PopoverDirection.bottomWithLeftAligned,
            offset: const Offset(0, 8),
            margin: EdgeInsets.zero,
            triggerActions: PopoverTriggerFlags.none,
            child: FlowyTextButton(
              LocaleKeys.settings_title.tr(),
              fontColor: AFThemeExtension.of(context).textColor,
              fillColor: Colors.transparent,
              hoverColor: AFThemeExtension.of(context).lightGreyHover,
              padding: GridSize.typeOptionContentInsets,
              onPressed: () => _popoverController.show(),
            ),
            popupBuilder: (BuildContext context) {
              return _GridSettingListPopover(settingContext: settingContext);
            },
          ),
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
  DatabaseSettingAction? _action;

  @override
  Widget build(BuildContext context) {
    if (_action == DatabaseSettingAction.showProperties) {
      return GridPropertyList(
        viewId: widget.settingContext.viewId,
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
    ).padding(all: 6.0);
  }
}
