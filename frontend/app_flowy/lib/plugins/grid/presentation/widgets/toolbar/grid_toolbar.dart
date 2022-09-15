import 'package:appflowy_popover/popover.dart';
import 'package:app_flowy/plugins/grid/application/setting/setting_bloc.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/field/field_controller.dart';
import '../../layout/sizes.dart';
import 'grid_property.dart';
import 'grid_setting.dart';

class GridToolbarContext {
  final String gridId;
  final GridFieldController fieldController;
  GridToolbarContext({
    required this.gridId,
    required this.fieldController,
  });
}

class GridToolbar extends StatelessWidget {
  final GridToolbarContext toolbarContext;
  const GridToolbar({required this.toolbarContext, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingContext = GridSettingContext(
      gridId: toolbarContext.gridId,
      fieldController: toolbarContext.fieldController,
    );
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(width: GridSize.leadingHeaderPadding),
          _SettingButton(settingContext: settingContext),
          const Spacer(),
        ],
      ),
    );
  }
}

class _SettingButton extends StatelessWidget {
  final GridSettingContext settingContext;
  const _SettingButton({required this.settingContext, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return AppFlowyStylePopover(
      constraints: BoxConstraints.loose(const Size(260, 400)),
      triggerActions: PopoverTriggerActionFlags.click,
      offset: const Offset(0, 10),
      child: FlowyIconButton(
        width: 22,
        hoverColor: theme.hover,
        icon: svgWidget(
          "grid/setting/setting",
          color: theme.iconColor,
        ).padding(horizontal: 3, vertical: 3),
      ),
      popupBuilder: (BuildContext context) {
        return _GridSettingListPopover(settingContext: settingContext);
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
    if (_action == GridSettingAction.properties) {
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
