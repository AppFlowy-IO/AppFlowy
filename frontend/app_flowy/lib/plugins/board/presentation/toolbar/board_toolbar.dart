import 'package:app_flowy/plugins/grid/application/field/field_cache.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'board_setting.dart';

class BoardToolbarContext {
  final String viewId;
  final GridFieldCache fieldCache;

  BoardToolbarContext({
    required this.viewId,
    required this.fieldCache,
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
          _SettingButton(
            settingContext: BoardSettingContext.from(toolbarContext),
          ),
        ],
      ),
    );
  }
}

class _SettingButton extends StatelessWidget {
  final BoardSettingContext settingContext;
  const _SettingButton({required this.settingContext, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppTheme>();
    return FlowyIconButton(
      hoverColor: theme.hover,
      width: 22,
      onPressed: () => BoardSettingList.show(context, settingContext),
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 3.0),
        child: svgWidget("grid/setting/setting"),
      ),
    );
  }
}
