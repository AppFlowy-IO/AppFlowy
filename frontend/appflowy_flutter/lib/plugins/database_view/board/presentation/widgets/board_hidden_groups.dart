import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

class HiddenGroupsColumn extends StatefulWidget {
  const HiddenGroupsColumn({super.key});

  @override
  State<HiddenGroupsColumn> createState() => _HiddenGroupsColumnState();
}

class _HiddenGroupsColumnState extends State<HiddenGroupsColumn> {
  bool isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      alignment: AlignmentDirectional.topStart,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 150),
      child: isCollapsed
          ? Padding(
              padding: const EdgeInsets.fromLTRB(48, 16, 8, 8),
              child: _collapseExpandIcon(),
            )
          : SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hidden group title
                  Padding(
                    // padding: const EdgeInsets.only(left: 48),
                    padding: const EdgeInsets.fromLTRB(48, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: FlowyText.medium(
                            'Hidden groups',
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        _collapseExpandIcon(),
                      ],
                    ),
                  ),
                  // Hidden grouop cards
                  Expanded(
                    child: ListView.separated(
                      itemCount: 50,
                      itemBuilder: (context, index) => const HiddenGroupCard(),
                      separatorBuilder: (context, index) => const VSpace(2),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _collapseExpandIcon() {
    return FlowyTooltip(
      message: isCollapsed ? "Expand group" : "Collpase group",
      child: FlowyIconButton(
        width: 20,
        height: 20,
        icon: FlowySvg(
          isCollapsed
              ? FlowySvgs.pull_left_outlined_s
              : FlowySvgs.pull_left_outlined_s,
        ),
        iconColorOnHover: Theme.of(context).colorScheme.onSurface,
        onPressed: () => setState(() {
          isCollapsed = !isCollapsed;
        }),
      ),
    );
  }
}

class HiddenGroupCard extends StatefulWidget {
  const HiddenGroupCard({super.key});

  @override
  State<HiddenGroupCard> createState() => _HiddenGroupCardState();
}

class _HiddenGroupCardState extends State<HiddenGroupCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: FlowyHover(
        onHover: (isHovering) => setState(() => _isHovering = isHovering),
        resetHoverOnRebuild: false,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                Opacity(
                  opacity: _isHovering ? 1 : 0,
                  child: const HiddenGroupCardActions(),
                ),
                const HSpace(4),
                const FlowyText.medium(
                  'In progress',
                  fontSize: 12,
                  overflow: TextOverflow.clip,
                ),
                const HSpace(6),
                FlowyText.medium(
                  '6',
                  fontSize: 12,
                  overflow: TextOverflow.clip,
                  color: Theme.of(context).hintColor,
                ),
                const Spacer(),
                Opacity(
                  opacity: _isHovering ? 1 : 0,
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: FlowySvg(
                      FlowySvgs.show_m,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HiddenGroupCardActions extends StatelessWidget {
  const HiddenGroupCardActions({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      width: 14,
      child: FlowySvg(
        FlowySvgs.drag_element_s,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}
