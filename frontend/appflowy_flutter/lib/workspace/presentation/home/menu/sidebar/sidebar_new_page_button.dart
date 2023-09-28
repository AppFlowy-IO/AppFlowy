import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/rename_view_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarNewPageButton extends StatelessWidget {
  const SidebarNewPageButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final child = FlowyTextButton(
      LocaleKeys.newPageText.tr(),
      fillColor: Colors.transparent,
      hoverColor: Colors.transparent,
      fontColor: Theme.of(context).colorScheme.tertiary,
      onPressed: () async => await createViewAndShowRenameDialogIfNeeded(
        context,
        LocaleKeys.newPageText.tr(),
        (viewName) {
          if (viewName.isNotEmpty) {
            context.read<MenuBloc>().add(MenuEvent.createApp(viewName));
          }
        },
      ),
      heading: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: FlowySvg(
          FlowySvgs.new_app_s,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      padding: const EdgeInsets.all(0),
    );

    return SizedBox(
      height: 60,
      child: TopBorder(
        color: Theme.of(context).dividerColor,
        child: child,
      ),
    );
  }
}
