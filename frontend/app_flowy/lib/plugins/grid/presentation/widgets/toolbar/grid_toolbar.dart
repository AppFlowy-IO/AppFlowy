import 'package:appflowy_popover/popover.dart';
import 'package:app_flowy/plugins/grid/application/setting/setting_bloc.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/field/field_cache.dart';
import '../../layout/sizes.dart';
import 'grid_property.dart';
import 'grid_setting.dart';

class GridToolbarContext {
  final String gridId;
  final GridFieldCache fieldCache;
  GridToolbarContext({
    required this.gridId,
    required this.fieldCache,
  });
}

class GridToolbar extends StatelessWidget {
  final GridToolbarContext toolbarContext;
  const GridToolbar({required this.toolbarContext, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingContext = GridSettingContext(
      gridId: toolbarContext.gridId,
      fieldCache: toolbarContext.fieldCache,
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
    return Popover(
      triggerActions: PopoverTriggerActionFlags.click,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 10),
      child: FlowyIconButton(
        width: 22,
        hoverColor: theme.hover,
        icon: svgWidget("grid/setting/setting")
            .padding(horizontal: 3, vertical: 3),
      ),
      popupBuilder: (BuildContext context) {
        return OverlayContainer(
          constraints: BoxConstraints.loose(const Size(140, 400)),
          child: GridSettingList(
            settingContext: settingContext,
            onAction: (action, settingContext) {
              switch (action) {
                case GridSettingAction.filter:
                  break;
                case GridSettingAction.sortBy:
                  break;
                case GridSettingAction.properties:
                  GridPropertyList(
                          gridId: settingContext.gridId,
                          fieldCache: settingContext.fieldCache)
                      .show(context);
                  break;
              }
            },
          ),
        );
      },
    );
    // return FlowyIconButton(
    //   onPressed: () => GridSettingList.show(context, settingContext),
    // );
  }
}
