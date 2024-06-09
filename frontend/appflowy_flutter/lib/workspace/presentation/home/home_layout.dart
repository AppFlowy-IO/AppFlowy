import 'dart:io' show Platform;

import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:sized_context/sized_context.dart';

import 'home_sizes.dart';

class HomeLayout {
  HomeLayout(BuildContext context) {
    final homeSetting = context.read<HomeSettingBloc>().state;
    showEditPanel = homeSetting.panelContext != null;
    menuWidth = Sizes.sideBarWidth;
    menuWidth += homeSetting.resizeOffset;

    final screenWidthPx = context.widthPx;
    context
        .read<HomeSettingBloc>()
        .add(HomeSettingEvent.checkScreenSize(screenWidthPx));

    showMenu = !homeSetting.isMenuCollapsed;
    if (showMenu) {
      menuIsDrawer = context.widthPx <= PageBreaks.tabletPortrait;
    }

    homePageLOffset = (showMenu && !menuIsDrawer) ? menuWidth : 0.0;

    menuSpacing = !showMenu && Platform.isMacOS ? 80.0 : 0.0;
    animDuration = homeSetting.resizeType.duration();
    editPanelWidth = HomeSizes.editPanelWidth;
    homePageROffset = showEditPanel ? editPanelWidth : 0;
  }

  late bool showEditPanel;
  late double menuWidth;
  late bool showMenu;
  late bool menuIsDrawer;
  late double homePageLOffset;
  late double menuSpacing;
  late Duration animDuration;
  late double editPanelWidth;
  late double homePageROffset;
}
