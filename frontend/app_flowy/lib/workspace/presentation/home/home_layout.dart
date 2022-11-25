import 'dart:io' show Platform;

import 'package:app_flowy/workspace/application/home/home_setting_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:sized_context/sized_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_sizes.dart';

class HomeLayout {
  late double menuWidth;
  late bool showMenu;
  late bool menuIsDrawer;
  late bool showEditPanel;
  late double editPanelWidth;
  late double homePageLOffset;
  late double homePageROffset;
  late double menuSpacing;
  late Duration animDuration;

  HomeLayout(BuildContext context, BoxConstraints homeScreenConstraint) {
    final homeSetting = context.read<HomeSettingBloc>().state;

    showEditPanel = homeSetting.panelContext.isSome();

    menuWidth = Sizes.sideBarMed;
    if (context.widthPx >= PageBreaks.desktop) {
      menuWidth = Sizes.sideBarLg;
    }

    menuWidth += homeSetting.resizeOffset;

    if (homeSetting.forceCollapse) {
      showMenu = false;
    } else {
      showMenu = true;
      menuIsDrawer = context.widthPx <= PageBreaks.tabletPortrait;
    }

    homePageLOffset = (showMenu && !menuIsDrawer) ? menuWidth : 0.0;

    menuSpacing = !showMenu && Platform.isMacOS ? 80.0 : 0.0;
    animDuration = homeSetting.resizeType.duration();

    editPanelWidth = HomeSizes.editPanelWidth;
    homePageROffset = showEditPanel ? editPanelWidth : 0;
  }
}
