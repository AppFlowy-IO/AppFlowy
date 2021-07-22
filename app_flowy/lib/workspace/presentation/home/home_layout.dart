import 'package:app_flowy/workspace/application/home_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:sized_context/sized_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_sizes.dart';

class HomeLayout {
  late double menuWidth;
  late bool showMenu;
  late bool showEditPannel;
  late double editPannelWidth;
  late double homePageLOffset;
  late double homePageROffset;
  late Duration animDuration;

  HomeLayout(BuildContext context, BoxConstraints homeScreenConstraint,
      bool forceCollapse) {
    final homeBlocState = context.read<HomeBloc>().state;

    showEditPannel = homeBlocState.editContext.isSome();

    menuWidth = Sizes.sideBarSm;
    if (context.widthPx >= PageBreaks.desktop) {
      menuWidth = Sizes.sideBarLg;
    }

    if (forceCollapse) {
      showMenu = false;
    } else {
      showMenu = context.widthPx > PageBreaks.tabletPortrait;
    }

    homePageLOffset = showMenu ? menuWidth : 0.0;
    animDuration = .35.seconds;

    editPannelWidth = HomeSizes.editPannelWidth;
    homePageROffset = showEditPannel ? editPannelWidth : 0;
  }
}
