import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarFolder extends StatelessWidget {
  const SidebarFolder({
    super.key,
    required this.views,
  });

  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: views
          .map(
            (view) => ViewItem(
              key: ValueKey(view.id),
              isFirstChild: view.id == views.first.id,
              view: view,
              level: 0,
              onSelected: (view) {
                getIt<MenuSharedState>().latestOpenView = view;
                context.read<MenuBloc>().add(MenuEvent.openPage(view.plugin()));
              },
            ),
          )
          .toList(),
    );
  }
}
