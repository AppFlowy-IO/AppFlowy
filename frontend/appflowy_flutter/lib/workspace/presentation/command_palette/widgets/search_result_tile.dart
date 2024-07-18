import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class SearchResultTile extends StatefulWidget {
  const SearchResultTile({
    super.key,
    required this.result,
    required this.onSelected,
    this.isTrashed = false,
  });

  final SearchResultPB result;
  final VoidCallback onSelected;
  final bool isTrashed;

  @override
  State<SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<SearchResultTile> {
  bool _hasFocus = false;

  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.result.getIcon();
    final cleanedPreview = _cleanPreview(widget.result.preview);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onSelected();

        getIt<ActionNavigationBloc>().add(
          ActionNavigationEvent.performAction(
            action: NavigationAction(objectId: widget.result.viewId),
          ),
        );
      },
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }

          if (event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onSelected();

            getIt<ActionNavigationBloc>().add(
              ActionNavigationEvent.performAction(
                action: NavigationAction(objectId: widget.result.viewId),
              ),
            );
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
        child: FlowyHover(
          isSelected: () => _hasFocus,
          style: HoverStyle(
            hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            foregroundColorOnHover: AFThemeExtension.of(context).textColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
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
                          if (widget.isTrashed) ...[
                            FlowyText(
                              LocaleKeys.commandPalette_fromTrashHint.tr(),
                              color: AFThemeExtension.of(context)
                                  .textColor
                                  .withAlpha(175),
                              fontSize: 10,
                            ),
                          ],
                          FlowyText(
                            widget.result.data,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (cleanedPreview.isNotEmpty) ...[
                  const VSpace(4),
                  _DocumentPreview(preview: cleanedPreview),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cleanPreview(String preview) {
    return preview.replaceAll('\n', ' ').trim();
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.preview});

  final String preview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16) +
          const EdgeInsets.only(left: 14),
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
