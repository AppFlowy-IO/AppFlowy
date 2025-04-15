import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchResultCell extends StatefulWidget {
  const SearchResultCell({
    super.key,
    required this.item,
    this.isTrashed = false,
    this.isHovered = false,
  });

  final SearchResultItem item;
  final bool isTrashed;
  final bool isHovered;

  @override
  State<SearchResultCell> createState() => _SearchResultCellState();
}

class _SearchResultCellState extends State<SearchResultCell> {
  bool _hasFocus = false;
  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  /// Helper to handle the selection action.
  void _handleSelection() {
    context.read<SearchResultListBloc>().add(
          SearchResultListEvent.openPage(pageId: widget.item.id),
        );
  }

  /// Helper to clean up preview text.
  String _cleanPreview(String preview) {
    return preview.replaceAll('\n', ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item.displayName.orDefault(
      LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
    );
    final icon = widget.item.icon.getIcon();
    final cleanedPreview = _cleanPreview(widget.item.content);
    final hasPreview = cleanedPreview.isNotEmpty;
    final trashHintText =
        widget.isTrashed ? LocaleKeys.commandPalette_fromTrashHint.tr() : null;

    // Build the tile content based on preview availability.
    Widget tileContent;
    if (hasPreview) {
      tileContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                SizedBox(width: 24, child: icon),
                const HSpace(6),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isTrashed)
                      FlowyText(
                        trashHintText!,
                        color: AFThemeExtension.of(context)
                            .textColor
                            .withAlpha(175),
                        fontSize: 10,
                      ),
                    FlowyText(
                      title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const VSpace(4),
          _DocumentPreview(preview: cleanedPreview),
        ],
      );
    } else {
      tileContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SizedBox(width: 24, child: icon),
            const HSpace(6),
          ],
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isTrashed)
                  FlowyText(
                    trashHintText!,
                    color:
                        AFThemeExtension.of(context).textColor.withAlpha(175),
                    fontSize: 10,
                  ),
                FlowyText(
                  title,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleSelection,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleSelection();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        onFocusChange: (hasFocus) {
          setState(() {
            context.read<SearchResultListBloc>().add(
                  SearchResultListEvent.onHoverResult(
                    item: widget.item,
                    userHovered: true,
                  ),
                );
            _hasFocus = hasFocus;
          });
        },
        child: FlowyHover(
          onHover: (value) {
            context.read<SearchResultListBloc>().add(
                  SearchResultListEvent.onHoverResult(
                    item: widget.item,
                    userHovered: true,
                  ),
                );
          },
          isSelected: () => _hasFocus || widget.isHovered,
          style: HoverStyle(
            borderRadius: BorderRadius.circular(8),
            hoverColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            foregroundColorOnHover: AFThemeExtension.of(context).textColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 30),
              child: tileContent,
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.preview});

  final String preview;

  @override
  Widget build(BuildContext context) {
    // Combine the horizontal padding for clarity:
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 16, 0),
      child: FlowyText.regular(
        preview,
        color: Theme.of(context).hintColor,
        fontSize: 12,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class SearchResultPreview extends StatelessWidget {
  const SearchResultPreview({
    super.key,
    required this.data,
  });

  final SearchResultItem data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: 0.5,
          child: FlowyText(
            LocaleKeys.commandPalette_pagePreview.tr(),
            fontSize: 12,
          ),
        ),
        const VSpace(6),
        Expanded(
          child: FlowyText(
            data.content,
            maxLines: 30,
          ),
        ),
      ],
    );
  }
}
