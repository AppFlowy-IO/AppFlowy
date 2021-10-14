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
  @override
  String get identifier => "TrashStackContext";

  @override
  List<Object?> get props => ["TrashStackContext"];

  @override
  Widget get titleWidget => const FlowyText.medium('Trash', fontSize: 12);

  @override
  HomeStackType get type => HomeStackType.trash;

  @override
  Widget render() {
    return const TrashStackPage(key: ValueKey('TrashStackPage'));
  }

  @override
  List<NavigationItem> get navigationItems => [this];
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
    return SizedBox.expand(
      child: Column(
        children: [
          _renderTopBar(theme),
          const VSpace(32),
          Expanded(
            child: ScrollbarListStack(
              axis: Axis.vertical,
              controller: _scrollController,
              barSize: 10,
              child: StyledSingleChildScrollView(
                controller: ScrollController(),
                axis: Axis.horizontal,
                child: SizedBox(
                  width: TrashSizes.totalWidth,
                  child: CustomScrollView(
                    shrinkWrap: true,
                    physics: StyledScrollPhysics(),
                    controller: _scrollController,
                    slivers: [
                      _renderListHeader(context),
                      _renderListBody(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.start,
      ).padding(horizontal: 80, vertical: 48),
    );
  }

  Widget _renderTopBar(AppTheme theme) {
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
              onTap: () {},
            ),
          ),
          const HSpace(6),
          SizedBox.fromSize(
            size: const Size(102, 30),
            child: FlowyButton(
              text: const FlowyText.medium('Delete all', fontSize: 12),
              icon: svg('editor/delete'),
              hoverColor: theme.hover,
              onTap: () {},
            ),
          )
        ],
      ),
    );
  }

  Widget _renderListHeader(BuildContext context) {
    return SliverPersistentHeader(
      delegate: TrashHeaderDelegate(),
      floating: true,
      pinned: true,
    );
  }

  Widget _renderListBody(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrashBloc>()..add(const TrashEvent.initial()),
      child: BlocBuilder<TrashBloc, TrashState>(
        builder: (context, state) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return SizedBox(
                  height: 42,
                  child: TrashCell(
                    object: state.objects[index],
                    onRestore: () {},
                    onDelete: () {},
                  ),
                );
              },
              childCount: state.objects.length,
            ),
          );
        },
      ),
    );
  }
}
