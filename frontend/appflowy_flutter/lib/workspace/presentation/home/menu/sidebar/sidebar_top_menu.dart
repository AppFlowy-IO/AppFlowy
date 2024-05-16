import 'dart:io' show Platform;

import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sidebar top menu is the top bar of the sidebar.
///
/// in the top menu, we have:
///   - appflowy icon (Windows or Linux)
///   - close / expand sidebar button
class SidebarTopMenu extends StatelessWidget {
  const SidebarTopMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarSectionsBloc, SidebarSectionsState>(
      builder: (context, _) => SizedBox(
        height: !PlatformExtension.isWindows ? HomeSizes.topBarHeight : 45,
        child: MoveWindowDetector(
          child: Row(
            children: [
              _buildLogoIcon(context),
              const Spacer(),
              _buildCollapseMenuButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoIcon(BuildContext context) {
    if (Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    final svgData = Theme.of(context).brightness == Brightness.dark
        ? FlowySvgs.flowy_logo_dark_mode_xl
        : FlowySvgs.flowy_logo_text_xl;

    return FlowySvg(
      svgData,
      size: const Size(92, 17),
      blendMode: null,
    );
  }

  Widget _buildCollapseMenuButton(BuildContext context) {
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: '${LocaleKeys.sideBar_closeSidebar.tr()}\n',
        ),
        TextSpan(
          text: Platform.isMacOS ? '⌘+.' : 'Ctrl+\\',
        ),
      ],
    );
    return FlowyTooltip(
      richMessage: textSpan,
      child: FlowyIconButton(
        width: 24,
        hoverColor: Colors.transparent,
        onPressed: () => context
            .read<HomeSettingBloc>()
            .add(const HomeSettingEvent.collapseMenu()),
        iconPadding: const EdgeInsets.all(2),
        icon: const FlowySvg(FlowySvgs.hide_menu_s),
      ),
    );
  }
}
