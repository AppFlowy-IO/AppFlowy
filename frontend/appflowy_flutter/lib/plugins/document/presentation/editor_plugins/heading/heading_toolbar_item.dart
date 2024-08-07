import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

final _headingData = [
  (FlowySvgs.h1_s, LocaleKeys.editor_heading1.tr()),
  (FlowySvgs.h2_s, LocaleKeys.editor_heading2.tr()),
  (FlowySvgs.h3_s, LocaleKeys.editor_heading3.tr()),
];

final headingsToolbarItem = ToolbarItem(
  id: 'editor.headings',
  group: 1,
  isActive: onlyShowInTextType,
  builder: (context, editorState, highlightColor, _, __) {
    final selection = editorState.selection!;
    final node = editorState.getNodeAtPath(selection.start.path)!;
    final delta = (node.delta ?? Delta()).toJson();
    int level = node.attributes[HeadingBlockKeys.level] ?? 1;
    final isHighlight =
        node.type == HeadingBlockKeys.type && (level >= 1 && level <= 3);
    // only supports the level 1 - 3 in the toolbar, ignore the other levels
    level = level.clamp(1, 3);

    final svg = _headingData[level - 1].$1;
    final message = _headingData[level - 1].$2;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: FlowyTooltip(
        message: message,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: _HeadingPopup(
            currentLevel: isHighlight ? level : -1,
            highlightColor: highlightColor,
            child: Row(
              children: [
                FlowySvg(
                  svg,
                  size: const Size.square(18),
                  color: isHighlight ? highlightColor : Colors.white,
                ),
                const HSpace(2.0),
                const FlowySvg(
                  FlowySvgs.arrow_down_s,
                  size: Size.square(12),
                  color: Colors.grey,
                ),
              ],
            ),
            onLevelChanged: (level) async {
              await editorState.formatNode(
                selection,
                (node) => node.copyWith(
                  type: isHighlight
                      ? ParagraphBlockKeys.type
                      : HeadingBlockKeys.type,
                  attributes: {
                    HeadingBlockKeys.level: level,
                    blockComponentBackgroundColor:
                        node.attributes[blockComponentBackgroundColor],
                    blockComponentTextDirection:
                        node.attributes[blockComponentTextDirection],
                    blockComponentDelta: delta,
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  },
);

class _HeadingPopup extends StatelessWidget {
  const _HeadingPopup({
    required this.currentLevel,
    required this.highlightColor,
    required this.onLevelChanged,
    required this.child,
  });

  final int currentLevel;
  final Color highlightColor;
  final Function(int level) onLevelChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      windowPadding: const EdgeInsets.all(0),
      margin: const EdgeInsets.all(4),
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 10),
      decorationColor: Theme.of(context).colorScheme.onTertiary,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      popupBuilder: (_) {
        keepEditorFocusNotifier.increase();
        return _HeadingButtons(
          currentLevel: currentLevel,
          highlightColor: highlightColor,
          onLevelChanged: onLevelChanged,
        );
      },
      onClose: () {
        keepEditorFocusNotifier.decrease();
      },
      child: child,
    );
  }
}

class _HeadingButtons extends StatelessWidget {
  const _HeadingButtons({
    required this.highlightColor,
    required this.currentLevel,
    required this.onLevelChanged,
  });

  final int currentLevel;
  final Color highlightColor;
  final Function(int level) onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HSpace(4),
          ..._headingData.mapIndexed((index, data) {
            final svg = data.$1;
            final message = data.$2;
            return [
              _HeadingButton(
                icon: svg,
                tooltip: message,
                onTap: () => onLevelChanged(index + 1),
                isHighlight: index + 1 == currentLevel,
                highlightColor: highlightColor,
              ),
              index != _headingData.length - 1
                  ? const _Divider()
                  : const SizedBox.shrink(),
            ];
          }).flattened,
          const HSpace(4),
        ],
      ),
    );
  }
}

class _HeadingButton extends StatelessWidget {
  const _HeadingButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.highlightColor,
    required this.isHighlight,
  });

  final Color highlightColor;
  final FlowySvgData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: FlowyTooltip(
          message: tooltip,
          preferBelow: true,
          child: FlowySvg(
            icon,
            size: const Size.square(18),
            color: isHighlight ? highlightColor : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 1,
        color: Colors.grey,
      ),
    );
  }
}
