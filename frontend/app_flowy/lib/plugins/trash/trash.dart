export "./src/sizes.dart";
export "./src/trash_cell.dart";
export "./src/trash_header.dart";

import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/trash/application/trash_bloc.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

import 'src/sizes.dart';
import 'src/trash_cell.dart';
import 'src/trash_header.dart';

class TrashPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return TrashPlugin(pluginType: pluginType);
  }

  @override
  String get menuName => "TrashPB";

  @override
  PluginType get pluginType => PluginType.trash;
}

class TrashPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class TrashPlugin extends Plugin {
  final PluginType _pluginType;

  TrashPlugin({required PluginType pluginType}) : _pluginType = pluginType;

  @override
  PluginDisplay get display => TrashPluginDisplay();

  @override
  PluginId get id => "TrashStack";

  @override
  PluginType get ty => _pluginType;
}

class TrashPluginDisplay extends PluginDisplay {
  @override
  Widget get leftBarItem =>
      FlowyText.medium(LocaleKeys.trash_text.tr(), fontSize: 12);

  @override
  Widget? get rightBarItem => null;

  @override
  Widget buildWidget() => const TrashPage(key: ValueKey('TrashPage'));

  @override
  List<NavigationItem> get navigationItems => [this];
}

class TrashPage extends StatefulWidget {
  const TrashPage({Key? key}) : super(key: key);

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    const horizontalPadding = 80.0;
    return BlocProvider(
      create: (context) => getIt<TrashBloc>()..add(const TrashEvent.initial()),
      child: BlocBuilder<TrashBloc, TrashState>(
        builder: (context, state) {
          return SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _renderTopBar(context, theme, state),
                const VSpace(32),
                _renderTrashList(context, state),
              ],
            ).padding(horizontal: horizontalPadding, vertical: 48),
          );
        },
      ),
    );
  }

  Widget _renderTrashList(BuildContext context, TrashState state) {
    const barSize = 6.0;
    return Expanded(
      child: ScrollbarListStack(
        axis: Axis.vertical,
        controller: _scrollController,
        scrollbarPadding: EdgeInsets.only(top: TrashSizes.headerHeight),
        barSize: barSize,
        child: StyledSingleChildScrollView(
          controller: ScrollController(),
          barSize: barSize,
          axis: Axis.horizontal,
          child: SizedBox(
            width: TrashSizes.totalWidth,
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: CustomScrollView(
                shrinkWrap: true,
                physics: StyledScrollPhysics(),
                controller: _scrollController,
                slivers: [
                  _renderListHeader(context, state),
                  _renderListBody(context, state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderTopBar(BuildContext context, AppTheme theme, TrashState state) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          FlowyText.semibold(LocaleKeys.trash_text.tr()),
          const Spacer(),
          SizedBox.fromSize(
            size: const Size(102, 30),
            child: FlowyButton(
              text: FlowyText.medium(LocaleKeys.trash_restoreAll.tr(),
                  fontSize: 12),
              leftIcon: svgWidget('editor/restore', color: theme.iconColor),
              hoverColor: theme.hover,
              onTap: () =>
                  context.read<TrashBloc>().add(const TrashEvent.restoreAll()),
            ),
          ),
          const HSpace(6),
          SizedBox.fromSize(
            size: const Size(102, 30),
            child: FlowyButton(
              text: FlowyText.medium(LocaleKeys.trash_deleteAll.tr(),
                  fontSize: 12),
              leftIcon: svgWidget('editor/delete', color: theme.iconColor),
              hoverColor: theme.hover,
              onTap: () =>
                  context.read<TrashBloc>().add(const TrashEvent.deleteAll()),
            ),
          )
        ],
      ),
    );
  }

  Widget _renderListHeader(BuildContext context, TrashState state) {
    return SliverPersistentHeader(
      delegate: TrashHeaderDelegate(),
      floating: true,
      pinned: true,
    );
  }

  Widget _renderListBody(BuildContext context, TrashState state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final object = state.objects[index];
          return SizedBox(
            height: 42,
            child: TrashCell(
              object: object,
              onRestore: () {
                context.read<TrashBloc>().add(TrashEvent.putback(object.id));
              },
              onDelete: () =>
                  context.read<TrashBloc>().add(TrashEvent.delete(object)),
            ),
          );
        },
        childCount: state.objects.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }
}
// class TrashScrollbar extends ScrollBehavior {
//   @override
//   Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
//     return ScrollbarListStack(
//       controller: details.controller,
//       axis: Axis.vertical,
//       barSize: 6,
//       child: child,
//     );
//   }
// }
