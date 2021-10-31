import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/trash/trash_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/stack_page/trash/widget/sizes.dart';
import 'package:app_flowy/workspace/presentation/stack_page/trash/widget/trash_cell.dart';
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
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import 'widget/trash_header.dart';

class TrashStackContext extends HomeStackContext {
  final ValueNotifier<bool> _isUpdated = ValueNotifier<bool>(false);

  @override
  String get identifier => "TrashStackContext";

  @override
  Widget get naviTitle => const FlowyText.medium('Trash', fontSize: 12);

  @override
  HomeStackType get type => HomeStackType.trash;

  @override
  Widget buildWidget() {
    return const TrashStackPage(key: ValueKey('TrashStackPage'));
  }

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  ValueNotifier<bool> get isUpdated => _isUpdated;

  @override
  void dispose() {}
}

class TrashStackPage extends StatefulWidget {
  const TrashStackPage({Key? key}) : super(key: key);

  @override
  State<TrashStackPage> createState() => _TrashStackPageState();
}

class _TrashStackPageState extends State<TrashStackPage> {
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
              children: [
                _renderTopBar(context, theme, state),
                const VSpace(32),
                _renderTrashList(context, state),
              ],
              mainAxisAlignment: MainAxisAlignment.start,
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
          const FlowyText.semibold('Trash'),
          const Spacer(),
          SizedBox.fromSize(
            size: const Size(102, 30),
            child: FlowyButton(
              text: const FlowyText.medium('Restore all', fontSize: 12),
              icon: svg('editor/restore'),
              hoverColor: theme.hover,
              onTap: () => context.read<TrashBloc>().add(const TrashEvent.restoreAll()),
            ),
          ),
          const HSpace(6),
          SizedBox.fromSize(
            size: const Size(102, 30),
            child: FlowyButton(
              text: const FlowyText.medium('Delete all', fontSize: 12),
              icon: svg('editor/delete'),
              hoverColor: theme.hover,
              onTap: () => context.read<TrashBloc>().add(const TrashEvent.deleteAll()),
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
              onDelete: () => context.read<TrashBloc>().add(TrashEvent.delete(object)),
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
