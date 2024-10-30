import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FindAndReplaceMenuWidget extends StatefulWidget {
  const FindAndReplaceMenuWidget({
    super.key,
    required this.onDismiss,
    required this.editorState,
    required this.showReplaceMenu,
  });

  final EditorState editorState;
  final VoidCallback onDismiss;

  /// Whether to show the replace menu initially
  final bool showReplaceMenu;

  @override
  State<FindAndReplaceMenuWidget> createState() =>
      _FindAndReplaceMenuWidgetState();
}

class _FindAndReplaceMenuWidgetState extends State<FindAndReplaceMenuWidget> {
  String queriedPattern = '';
  late bool showReplaceMenu = widget.showReplaceMenu;

  final findFocusNode = FocusNode();
  final replaceFocusNode = FocusNode();

  late SearchServiceV3 searchService = SearchServiceV3(
    editorState: widget.editorState,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showReplaceMenu) {
        replaceFocusNode.requestFocus();
      } else {
        findFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    findFocusNode.dispose();
    replaceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: FindMenu(
              onDismiss: widget.onDismiss,
              editorState: widget.editorState,
              searchService: searchService,
              focusNode: findFocusNode,
              showReplaceMenu: showReplaceMenu,
              onToggleShowReplace: () => setState(() {
                showReplaceMenu = !showReplaceMenu;
              }),
            ),
          ),
          if (showReplaceMenu)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8.0,
              ),
              child: ReplaceMenu(
                editorState: widget.editorState,
                searchService: searchService,
                focusNode: replaceFocusNode,
              ),
            ),
        ],
      ),
    );
  }
}

class FindMenu extends StatefulWidget {
  const FindMenu({
    super.key,
    required this.editorState,
    required this.searchService,
    required this.showReplaceMenu,
    required this.focusNode,
    required this.onDismiss,
    required this.onToggleShowReplace,
  });

  final EditorState editorState;
  final SearchServiceV3 searchService;

  final bool showReplaceMenu;
  final FocusNode focusNode;

  final VoidCallback onDismiss;
  final void Function() onToggleShowReplace;

  @override
  State<FindMenu> createState() => _FindMenuState();
}

class _FindMenuState extends State<FindMenu> {
  final textController = TextEditingController();

  bool caseSensitive = false;

  @override
  void initState() {
    super.initState();

    widget.searchService.matchWrappers.addListener(_setState);
    widget.searchService.currentSelectedIndex.addListener(_setState);

    textController.addListener(_searchPattern);
  }

  @override
  void dispose() {
    widget.searchService.matchWrappers.removeListener(_setState);
    widget.searchService.currentSelectedIndex.removeListener(_setState);
    widget.searchService.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // the selectedIndex from searchService is 0-based
    final selectedIndex = widget.searchService.selectedIndex + 1;
    final matches = widget.searchService.matchWrappers.value;
    return Row(
      children: [
        const HSpace(4.0),
        // expand/collapse button
        _FindAndReplaceIcon(
          icon: widget.showReplaceMenu
              ? FlowySvgs.drop_menu_show_s
              : FlowySvgs.drop_menu_hide_s,
          tooltipText: '',
          onPressed: widget.onToggleShowReplace,
        ),
        const HSpace(4.0),
        // find text input
        SizedBox(
          width: 200,
          height: 30,
          child: TextField(
            key: const Key('findTextField'),
            focusNode: widget.focusNode,
            controller: textController,
            style: Theme.of(context).textTheme.bodyMedium,
            onSubmitted: (_) {
              widget.searchService.navigateToMatch();

              // after update selection or navigate to match, the editor
              // will request focus, here's a workaround to request the
              // focus back to the text field
              Future.delayed(
                const Duration(milliseconds: 50),
                () => widget.focusNode.requestFocus(),
              );
            },
            decoration: _buildInputDecoration(
              LocaleKeys.findAndReplace_find.tr(),
            ),
          ),
        ),
        // the count of matches
        Container(
          constraints: const BoxConstraints(minWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          alignment: Alignment.centerLeft,
          child: FlowyText(
            matches.isEmpty
                ? LocaleKeys.findAndReplace_noResult.tr()
                : '$selectedIndex of ${matches.length}',
          ),
        ),
        const HSpace(4.0),
        // case sensitive button
        _FindAndReplaceIcon(
          icon: FlowySvgs.text_s,
          tooltipText: LocaleKeys.findAndReplace_caseSensitive.tr(),
          onPressed: () => setState(() {
            caseSensitive = !caseSensitive;
            widget.searchService.caseSensitive = caseSensitive;
          }),
          isSelected: caseSensitive,
        ),
        const HSpace(4.0),
        // previous match button
        _FindAndReplaceIcon(
          onPressed: () => widget.searchService.navigateToMatch(moveUp: true),
          icon: FlowySvgs.arrow_up_s,
          tooltipText: LocaleKeys.findAndReplace_previousMatch.tr(),
        ),
        const HSpace(4.0),
        // next match button
        _FindAndReplaceIcon(
          onPressed: () => widget.searchService.navigateToMatch(),
          icon: FlowySvgs.arrow_down_s,
          tooltipText: LocaleKeys.findAndReplace_nextMatch.tr(),
        ),
        const HSpace(4.0),
        _FindAndReplaceIcon(
          onPressed: widget.onDismiss,
          icon: FlowySvgs.close_s,
          tooltipText: LocaleKeys.findAndReplace_close.tr(),
        ),
        const HSpace(4.0),
      ],
    );
  }

  void _searchPattern() {
    widget.searchService.findAndHighlight(textController.text);
    _setState();
  }

  void _setState() {
    setState(() {});
  }
}

class ReplaceMenu extends StatefulWidget {
  const ReplaceMenu({
    super.key,
    required this.editorState,
    required this.searchService,
    required this.focusNode,
  });

  final EditorState editorState;
  final SearchServiceV3 searchService;

  final FocusNode focusNode;

  @override
  State<ReplaceMenu> createState() => _ReplaceMenuState();
}

class _ReplaceMenuState extends State<ReplaceMenu> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // placeholder for aligning the replace menu
        const HSpace(30),
        SizedBox(
          width: 200,
          height: 30,
          child: TextField(
            key: const Key('replaceTextField'),
            focusNode: widget.focusNode,
            controller: textController,
            style: Theme.of(context).textTheme.bodyMedium,
            onSubmitted: (_) {
              _replaceSelectedWord();

              Future.delayed(
                const Duration(milliseconds: 50),
                () => widget.focusNode.requestFocus(),
              );
            },
            decoration: _buildInputDecoration(
              LocaleKeys.findAndReplace_replace.tr(),
            ),
          ),
        ),
        _FindAndReplaceIcon(
          onPressed: _replaceSelectedWord,
          iconBuilder: (_) => const Icon(
            Icons.find_replace_outlined,
            size: 16,
          ),
          tooltipText: LocaleKeys.findAndReplace_replace.tr(),
        ),
        const HSpace(4.0),
        _FindAndReplaceIcon(
          iconBuilder: (_) => const Icon(
            Icons.change_circle_outlined,
            size: 16,
          ),
          tooltipText: LocaleKeys.findAndReplace_replaceAll.tr(),
          onPressed: () => widget.searchService.replaceAllMatches(
            textController.text,
          ),
        ),
      ],
    );
  }

  void _replaceSelectedWord() {
    widget.searchService.replaceSelectedWord(textController.text);
  }
}

class _FindAndReplaceIcon extends StatelessWidget {
  const _FindAndReplaceIcon({
    required this.onPressed,
    required this.tooltipText,
    this.icon,
    this.iconBuilder,
    this.isSelected,
  });

  final VoidCallback onPressed;
  final FlowySvgData? icon;
  final WidgetBuilder? iconBuilder;
  final String tooltipText;
  final bool? isSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 24,
      height: 24,
      onPressed: onPressed,
      icon: iconBuilder?.call(context) ??
          (icon != null ? FlowySvg(icon!) : const Placeholder()),
      tooltipText: tooltipText,
      isSelected: isSelected,
      iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
    );
  }
}

InputDecoration _buildInputDecoration(String hintText) {
  return InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    border: const UnderlineInputBorder(),
    hintText: hintText,
  );
}
