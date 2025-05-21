import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

class ViewDatabaseButton extends StatelessWidget {
  const ViewDatabaseButton({super.key, required this.view});

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: FlowyIconButton(
        tooltipText: LocaleKeys.grid_rowPage_openAsFullPage.tr(),
        width: 24,
        height: 24,
        iconPadding: const EdgeInsets.all(3),
        icon: const FlowySvg(FlowySvgs.database_fullscreen_s),
        onPressed: () {
          getIt<TabsBloc>().add(
            TabsEvent.openPlugin(
              plugin: view.plugin(),
              view: view,
            ),
          );
        },
      ),
    );
  }
}
