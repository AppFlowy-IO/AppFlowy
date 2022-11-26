import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import 'board_setting.dart';

class BoardToolbarContext {
  final String viewId;
  final GridFieldController fieldController;

  BoardToolbarContext({
    required this.viewId,
    required this.fieldController,
  });
}

class BoardToolbar extends StatelessWidget {
  final BoardToolbarContext toolbarContext;
  const BoardToolbar({
    required this.toolbarContext,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const Spacer(),
          _SettingButton(
            settingContext: BoardSettingContext.from(toolbarContext),
          ),
        ],
      ),
    );
  }
}

class _SettingButton extends StatefulWidget {
  final BoardSettingContext settingContext;
  const _SettingButton({required this.settingContext, Key? key})
      : super(key: key);

  @override
  State<_SettingButton> createState() => _SettingButtonState();
}

class _SettingButtonState extends State<_SettingButton> {
  late PopoverController popoverController;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.leftWithTopAligned,
      triggerActions: PopoverTriggerFlags.none,
      constraints: BoxConstraints.loose(const Size(260, 400)),
      child: FlowyTextButton(
        LocaleKeys.settings_title.tr(),
        fontSize: 14,
        fillColor: Colors.transparent,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        onPressed: () {
          popoverController.show();
        },
      ),
      popupBuilder: (BuildContext popoverContext) {
        return BoardSettingListPopover(
          settingContext: widget.settingContext,
          popoverController: popoverController,
        );
      },
    );
  }
}
