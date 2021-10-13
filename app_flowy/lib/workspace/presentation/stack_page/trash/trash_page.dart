import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

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
    return const TrashStackPage();
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
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox.expand(
      child: Column(
        children: [
          _renderTopBar(theme),
          _renderTrashList(context, theme),
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

  Widget _renderTrashList(BuildContext context, AppTheme theme) {
    return Expanded(
      child: CustomScrollView(
        physics: StyledScrollPhysics(),
        slivers: [
          _renderListHeader(context),
          _renderListBody(context),
        ],
      ),
    );
  }

  Widget _renderListHeader(BuildContext context) {
    return const SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.green,
      title: Text('Have a nice day'),
      floating: true,
    );
  }

  Widget _renderListBody(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Card(
            child: Container(
              color: Colors.blue[100 * (index % 9 + 1)],
              height: 80,
              alignment: Alignment.center,
              child: Text(
                "Item $index",
                style: const TextStyle(fontSize: 30),
              ),
            ),
          );
        },
        childCount: 3,
      ),
    );
  }
}
