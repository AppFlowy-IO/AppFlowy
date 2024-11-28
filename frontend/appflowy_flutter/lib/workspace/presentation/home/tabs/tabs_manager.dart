import 'package:appflowy/core/frameless_window.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TabsManager extends StatelessWidget {
  const TabsManager({super.key, required this.onIndexChanged});

  final void Function(int) onIndexChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TabsBloc>.value(
      value: context.read<TabsBloc>(),
      child: BlocListener<TabsBloc, TabsState>(
        listenWhen: (prev, curr) =>
            prev.currentIndex != curr.currentIndex || prev.pages != curr.pages,
        listener: (context, state) => onIndexChanged(state.currentIndex),
        child: BlocBuilder<TabsBloc, TabsState>(
          builder: (context, state) {
            if (state.pages == 1) {
              return const SizedBox.shrink();
            }

            return Container(
              alignment: Alignment.bottomLeft,
              height: HomeSizes.tabBarHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: MoveWindowDetector(
                child: Row(
                  children: state.pageManagers.map<Widget>((pm) {
                    return Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: HomeSizes.tabBarWidth,
                        ),
                        child: FlowyTab(
                          key: ValueKey('tab-${pm.plugin.id}'),
                          pageManager: pm,
                          isCurrent: state.currentPageManager == pm,
                          onTap: () {
                            if (state.currentPageManager != pm) {
                              final index = state.pageManagers.indexOf(pm);
                              onIndexChanged(index);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
