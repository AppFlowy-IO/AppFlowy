import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedPagesList extends StatelessWidget {
  const SharedPagesList({
    super.key,
    required this.sharedPages,
  });

  final SharedPages sharedPages;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sharedPages.map((sharedPage) {
        final view = sharedPage.view;
        return ViewItem(
          key: ValueKey(view.id),
          spaceType: FolderSpaceType.public,
          isFirstChild: view.id == sharedPages.first.view.id,
          view: view,
          level: 0,
          isDraggable: false, // disable draggable for shared pages
          leftPadding: HomeSpaceViewSizes.leftPadding,
          isFeedback: false,
          onSelected: (context, view) {
            if (HardwareKeyboard.instance.isControlPressed) {
              context.read<TabsBloc>().openTab(view);
            }
            context.read<TabsBloc>().openPlugin(view);
          },
          onTertiarySelected: (context, view) =>
              context.read<TabsBloc>().openTab(view),
        );
      }).toList(),
    );
  }
}
