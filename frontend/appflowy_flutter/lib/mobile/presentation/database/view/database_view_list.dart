import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/tab_bar_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
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
  const MobileDatabaseViewList({super.key, required this.databaseController});

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewBloc, ViewState>(
      builder: (context, state) {
        final views = [state.view, ...state.view.childViews];
        final children = [
          const Center(child: DragHandler()),
          const _Header(),
          ...views.mapIndexed(
            (index, view) => MobileDatabaseViewListButton(
              view: view,
              databaseController: databaseController,
              showTopBorder: index == 0,
            ),
          ),
          const VSpace(20),
          const MobileNewDatabaseViewButton(),
        ];

        return Column(
          children: children,
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    const iconWidth = 30.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FlowyIconButton(
              icon: const FlowySvg(
                FlowySvgs.close_s,
                size: Size.square(iconWidth),
              ),
              width: iconWidth,
              iconPadding: EdgeInsets.zero,
              onPressed: () => context.pop(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: FlowyText.medium(
              LocaleKeys.grid_settings_viewList.tr(),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
class MobileDatabaseViewListButton extends StatelessWidget {
  const MobileDatabaseViewListButton({
    super.key,
    required this.view,
    required this.databaseController,
    required this.showTopBorder,
  });

  final ViewPB view;
  final DatabaseController databaseController;
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
          trailing: _trailing(context, isSelected),
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

  Widget _trailing(BuildContext context, bool isSelected) {
    final more = FlowyIconButton(
      icon: FlowySvg(
        FlowySvgs.three_dots_s,
        size: const Size.square(20),
        color: Theme.of(context).hintColor,
      ),
      onPressed: () {
        showMobileBottomSheet(
          context,
          padding: EdgeInsets.zero,
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
            FlowySvgs.blue_check_s,
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
          padding: EdgeInsets.zero,
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
        const Center(child: DragHandler()),
        _CreateViewHeader(
          textController: controller,
          selectedLayout: layoutType,
        ),
        FlowyOptionTile.textField(
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

class _CreateViewHeader extends StatelessWidget {
  const _CreateViewHeader({
    required this.textController,
    required this.selectedLayout,
  });

  final TextEditingController textController;
  final DatabaseLayoutPB selectedLayout;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox.square(
              dimension: 36,
              child: IconButton(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                icon: const FlowySvg(
                  FlowySvgs.arrow_left_s,
                  size: Size.square(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  enableFeedback: true,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  context.pop((selectedLayout, textController.text.trim()));
                },
                child: FlowyText.medium(
                  LocaleKeys.button_done.tr(),
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        Center(
          child: FlowyText.medium(
            LocaleKeys.grid_settings_createView.tr(),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
