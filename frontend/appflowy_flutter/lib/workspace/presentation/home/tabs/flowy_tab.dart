import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowyTab extends StatefulWidget {
  const FlowyTab({
    super.key,
    required this.pageManager,
    required this.isCurrent,
  });

  final PageManager pageManager;
  final bool isCurrent;

  @override
  State<FlowyTab> createState() => _FlowyTabState();
}

class _FlowyTabState extends State<FlowyTab> {

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      style: HoverStyle(
        borderRadius: BorderRadius.zero,
        backgroundColor: _getBackgroundColor(),
      ),
      builder: (context, onHover) {
        return ChangeNotifierProvider.value(
          value: widget.pageManager.notifier,
          child: Consumer<PageNotifier>(
            builder: (context, value, child) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: HomeSizes.tabBarWidth,
                height: HomeSizes.tabBarHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: widget.pageManager.notifier
                          .tabBarWidget(widget.pageManager.plugin.id),
                    ),
                    Visibility(
                      visible: onHover,
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: FlowyIconButton(
                          onPressed: _closeTab,
                          icon: const FlowySvg(
                            FlowySvgs.close_s,
                            size: Size.square(22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    if (widget.isCurrent) {
      return Theme.of(context).colorScheme.onSecondaryContainer;
    }

    if (_isHovering) {
      return AFThemeExtension.of(context).lightGreyHover;
    }

    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  void _closeTab([TapUpDetails? details]) => context
      .read<TabsBloc>()
      .add(TabsEvent.closeTab(widget.pageManager.plugin.id));
}
