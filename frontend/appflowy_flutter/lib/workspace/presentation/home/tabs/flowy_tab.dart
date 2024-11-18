import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class FlowyTab extends StatefulWidget {
  const FlowyTab({
    super.key,
    required this.pageManager,
    required this.isCurrent,
    required this.onTap,
  });

  final PageManager pageManager;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  State<FlowyTab> createState() => _FlowyTabState();
}

class _FlowyTabState extends State<FlowyTab> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      resetHoverOnRebuild: false,
      style: HoverStyle(
        borderRadius: BorderRadius.zero,
        backgroundColor: widget.isCurrent
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        hoverColor:
            widget.isCurrent ? Theme.of(context).colorScheme.surface : null,
      ),
      builder: (context, isHovering) => AppFlowyPopover(
        controller: controller,
        offset: const Offset(4, 4),
        triggerActions: PopoverTriggerFlags.secondaryClick,
        showAtCursor: true,
        popupBuilder: (_) => BlocProvider.value(
          value: context.read<TabsBloc>(),
          child: TabMenu(pageId: widget.pageManager.plugin.id),
        ),
        child: ChangeNotifierProvider.value(
          value: widget.pageManager.notifier,
          child: Consumer<PageNotifier>(
            builder: (context, value, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // We use a Listener to avoid gesture detector onPanStart debounce
              child: Listener(
                onPointerDown: (event) {
                  if (event.buttons == kPrimaryButton) {
                    widget.onTap();
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Stop move window detector
                  onPanStart: (_) {},
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: HomeSizes.tabBarWidth,
                      minWidth: 100,
                    ),
                    height: HomeSizes.tabBarHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: widget.pageManager.notifier
                              .tabBarWidget(widget.pageManager.plugin.id),
                        ),
                        Visibility(
                          visible: isHovering,
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: FlowyIconButton(
                              onPressed: () => _closeTab(context),
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
            ),
          ),
        ),
      ),
    );
  }

  void _closeTab(BuildContext context) => context
      .read<TabsBloc>()
      .add(TabsEvent.closeTab(widget.pageManager.plugin.id));
}

@visibleForTesting
class TabMenu extends StatelessWidget {
  const TabMenu({super.key, required this.pageId});

  final String pageId;

  @override
  Widget build(BuildContext context) {
    return SeparatedColumn(
      separatorBuilder: () => const VSpace(4),
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyButton(
          text: FlowyText.regular(LocaleKeys.tabMenu_close.tr()),
          onTap: () => _closeTab(context),
        ),
        FlowyButton(
          text: FlowyText.regular(
            LocaleKeys.tabMenu_closeOthers.tr(),
          ),
          onTap: () => _closeOtherTabs(context),
        ),
      ],
    );
  }

  void _closeTab(BuildContext context) =>
      context.read<TabsBloc>().add(TabsEvent.closeTab(pageId));

  void _closeOtherTabs(BuildContext context) =>
      context.read<TabsBloc>().add(TabsEvent.closeOtherTabs(pageId));
}
