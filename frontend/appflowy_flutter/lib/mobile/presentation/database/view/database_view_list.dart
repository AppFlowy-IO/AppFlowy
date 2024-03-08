import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'database_view_layout.dart';
import 'database_view_quick_actions.dart';

/// [MobileDatabaseViewList] shows a list of all the views in the database and
/// adds a button to create a new database view.
class MobileDatabaseViewList extends StatelessWidget {
  const MobileDatabaseViewList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewBloc, ViewState>(
      builder: (context, state) {
        final views = [state.view, ...state.view.childViews];

        return Column(
          children: [
            _Header(
              title: LocaleKeys.grid_settings_viewList.plural(
                context.watch<DatabaseTabBarBloc>().state.tabBars.length,
                namedArgs: {
                  'count':
                      '${context.watch<DatabaseTabBarBloc>().state.tabBars.length}',
                },
              ),
              showBackButton: false,
              useFilledDoneButton: false,
              onDone: (context) => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  ...views.mapIndexed(
                    (index, view) => MobileDatabaseViewListButton(
                      view: view,
                      showTopBorder: index == 0,
                    ),
                  ),
                  const VSpace(20),
                  const MobileNewDatabaseViewButton(),
                  VSpace(
                    context.bottomSheetPadding(ignoreViewPadding: false),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Same header as the one in showMobileBottomSheet, but allows popping the
/// sheet with a value.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.showBackButton,
    required this.useFilledDoneButton,
    required this.onDone,
  });

  final String title;
  final bool showBackButton;
  final bool useFilledDoneButton;
  final void Function(BuildContext context) onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: SizedBox(
        height: 44.0,
        child: Stack(
          children: [
            if (showBackButton)
              const Align(
                alignment: Alignment.centerLeft,
                child: AppBarBackButton(),
              ),
            Align(
              child: FlowyText.medium(
                title,
                fontSize: 16.0,
              ),
            ),
            useFilledDoneButton
                ? Align(
                    alignment: Alignment.centerRight,
                    child: AppBarFilledDoneButton(
                      onTap: () => onDone(context),
                    ),
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: AppBarDoneButton(
                      onTap: () => onDone(context),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class MobileDatabaseViewListButton extends StatelessWidget {
  const MobileDatabaseViewListButton({
    super.key,
    required this.view,
    required this.showTopBorder,
  });

  final ViewPB view;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
      builder: (context, state) {
        final index =
            state.tabBars.indexWhere((tabBar) => tabBar.viewId == view.id);
        final isSelected = index == state.selectedIndex;
        return FlowyOptionTile.text(
          text: view.name,
          onTap: () {
            context
                .read<DatabaseTabBarBloc>()
                .add(DatabaseTabBarEvent.selectView(view.id));
          },
          leftIcon: _buildViewIconButton(context, view),
          trailing: _trailing(
            context,
            state.tabBarControllerByViewId[view.id]!.controller,
            isSelected,
          ),
          showTopBorder: showTopBorder,
        );
      },
    );
  }

  Widget _buildViewIconButton(BuildContext context, ViewPB view) {
    return SizedBox.square(
      dimension: 20.0,
      child: view.defaultIcon(),
    );
  }

  Widget _trailing(
    BuildContext context,
    DatabaseController databaseController,
    bool isSelected,
  ) {
    final more = FlowyIconButton(
      icon: FlowySvg(
        FlowySvgs.three_dots_s,
        size: const Size.square(20),
        color: Theme.of(context).hintColor,
      ),
      onPressed: () {
        showMobileBottomSheet(
          context,
          showDragHandle: true,
          backgroundColor: Theme.of(context).colorScheme.background,
          builder: (_) {
            return BlocProvider<ViewBloc>(
              create: (_) =>
                  ViewBloc(view: view)..add(const ViewEvent.initial()),
              child: MobileDatabaseViewQuickActions(
                view: view,
                databaseController: databaseController,
              ),
            );
          },
        );
      },
    );
    if (isSelected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlowySvg(
            FlowySvgs.m_blue_check_s,
            size: Size.square(20),
            blendMode: BlendMode.dst,
          ),
          const HSpace(8),
          more,
        ],
      );
    } else {
      return more;
    }
  }
}

class MobileNewDatabaseViewButton extends StatelessWidget {
  const MobileNewDatabaseViewButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      text: LocaleKeys.grid_settings_createView.tr(),
      textColor: Theme.of(context).hintColor,
      leftIcon: FlowySvg(
        FlowySvgs.add_s,
        size: const Size.square(20),
        color: Theme.of(context).hintColor,
      ),
      onTap: () async {
        final result = await showMobileBottomSheet<(DatabaseLayoutPB, String)>(
          context,
          showDragHandle: true,
          builder: (_) {
            return const MobileCreateDatabaseView();
          },
        );
        if (context.mounted && result != null) {
          context
              .read<DatabaseTabBarBloc>()
              .add(DatabaseTabBarEvent.createView(result.$1, result.$2));
        }
      },
    );
  }
}

class MobileCreateDatabaseView extends StatefulWidget {
  const MobileCreateDatabaseView({super.key});

  @override
  State<MobileCreateDatabaseView> createState() =>
      _MobileCreateDatabaseViewState();
}

class _MobileCreateDatabaseViewState extends State<MobileCreateDatabaseView> {
  late final TextEditingController controller;
  DatabaseLayoutPB layoutType = DatabaseLayoutPB.Grid;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: LocaleKeys.grid_title_placeholder.tr(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(
          title: LocaleKeys.grid_settings_createView.tr(),
          showBackButton: true,
          useFilledDoneButton: true,
          onDone: (context) =>
              context.pop((layoutType, controller.text.trim())),
        ),
        FlowyOptionTile.textField(
          autofocus: true,
          controller: controller,
        ),
        const VSpace(20),
        DatabaseViewLayoutPicker(
          selectedLayout: layoutType,
          onSelect: (layout) {
            setState(() => layoutType = layout);
          },
        ),
      ],
    );
  }
}
