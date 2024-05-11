import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/base/mobile_view_page_bloc.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/base/view_page/more_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/page_style_bottom_sheet.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileViewPageImmersiveAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MobileViewPageImmersiveAppBar({
    super.key,
    required this.preferredSize,
    required this.appBarOpacity,
    required this.title,
    required this.actions,
  });

  final ValueListenable appBarOpacity;
  final Widget title;
  final List<Widget> actions;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appBarOpacity,
      builder: (_, opacity, __) => FlowyAppBar(
        backgroundColor:
            AppBarTheme.of(context).backgroundColor?.withOpacity(opacity),
        showDivider: false,
        title: Opacity(opacity: opacity >= 0.99 ? 1.0 : 0, child: title),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
          child: _buildAppBarBackButton(context),
        ),
        actions: actions,
      ),
    );
  }

  Widget _buildAppBarBackButton(BuildContext context) {
    return AppBarButton(
      padding: EdgeInsets.zero,
      onTap: (context) => context.pop(),
      child: _ImmersiveAppBarButton(
        icon: FlowySvgs.m_app_bar_back_s,
        dimension: 30.0,
        iconPadding: 6.0,
        isImmersiveMode:
            context.read<MobileViewPageBloc>().state.isImmersiveMode,
        appBarOpacity: appBarOpacity,
      ),
    );
  }
}

class MobileViewPageMoreButton extends StatelessWidget {
  const MobileViewPageMoreButton({
    super.key,
    required this.view,
    required this.isImmersiveMode,
    required this.appBarOpacity,
  });

  final ViewPB view;
  final bool isImmersiveMode;
  final ValueListenable appBarOpacity;

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      padding: const EdgeInsets.only(left: 8, right: 16),
      onTap: (context) {
        EditorNotification.exitEditing().post();

        showMobileBottomSheet(
          context,
          showDragHandle: true,
          showDivider: false,
          backgroundColor: Theme.of(context).colorScheme.background,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<ViewBloc>()),
              BlocProvider.value(value: context.read<FavoriteBloc>()),
            ],
            child: MobileViewPageMoreBottomSheet(view: view),
          ),
        );
      },
      child: _ImmersiveAppBarButton(
        icon: FlowySvgs.m_app_bar_more_s,
        dimension: 30.0,
        iconPadding: 5.0,
        isImmersiveMode: isImmersiveMode,
        appBarOpacity: appBarOpacity,
      ),
    );
  }
}

class MobileViewPageLayoutButton extends StatelessWidget {
  const MobileViewPageLayoutButton({
    super.key,
    required this.view,
    required this.isImmersiveMode,
    required this.appBarOpacity,
  });

  final ViewPB view;
  final bool isImmersiveMode;
  final ValueListenable appBarOpacity;

  @override
  Widget build(BuildContext context) {
    // only display the layout button if the view is a document
    if (view.layout != ViewLayoutPB.Document) {
      return const SizedBox.shrink();
    }

    return AppBarButton(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      onTap: (context) {
        EditorNotification.exitEditing().post();

        showMobileBottomSheet(
          context,
          showDragHandle: true,
          showDivider: false,
          showDoneButton: true,
          showHeader: true,
          title: LocaleKeys.pageStyle_title.tr(),
          backgroundColor: Theme.of(context).colorScheme.background,
          builder: (_) => BlocProvider.value(
            value: context.read<DocumentPageStyleBloc>(),
            child: PageStyleBottomSheet(
              view: context.read<ViewBloc>().state.view,
            ),
          ),
        );
      },
      child: _ImmersiveAppBarButton(
        icon: FlowySvgs.m_layout_s,
        dimension: 30.0,
        iconPadding: 5.0,
        isImmersiveMode: isImmersiveMode,
        appBarOpacity: appBarOpacity,
      ),
    );
  }
}

class _ImmersiveAppBarButton extends StatelessWidget {
  const _ImmersiveAppBarButton({
    required this.icon,
    required this.dimension,
    required this.iconPadding,
    required this.isImmersiveMode,
    required this.appBarOpacity,
  });

  final FlowySvgData icon;
  final double dimension;
  final double iconPadding;
  final bool isImmersiveMode;
  final ValueListenable appBarOpacity;

  @override
  Widget build(BuildContext context) {
    assert(
      dimension > 0.0 && dimension <= kToolbarHeight,
      'dimension must be greater than 0, and less than or equal to kToolbarHeight',
    );

    // if the immersive mode is on, the icon should be white and add a black background
    //  also, the icon opacity will change based on the app bar opacity
    return UnconstrainedBox(
      child: SizedBox.square(
        dimension: dimension,
        child: ValueListenableBuilder(
          valueListenable: appBarOpacity,
          builder: (context, appBarOpacity, child) {
            Color? color;

            // if there's no cover or the cover is not immersive,
            //  make sure the app bar is always visible
            if (!isImmersiveMode) {
              color = null;
            } else if (appBarOpacity < 0.99) {
              color = Colors.white;
            }

            Widget child = Container(
              margin: EdgeInsets.all(iconPadding),
              child: FlowySvg(icon, color: color),
            );

            if (isImmersiveMode && appBarOpacity <= 0.99) {
              child = DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(dimension / 2.0),
                  color: Colors.black.withOpacity(0.2),
                ),
                child: child,
              );
            }

            return child;
          },
        ),
      ),
    );
  }
}
