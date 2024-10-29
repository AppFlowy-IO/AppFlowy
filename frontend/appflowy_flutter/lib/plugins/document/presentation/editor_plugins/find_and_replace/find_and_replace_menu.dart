import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text_input.dart';

class FindAndReplaceMenuWidget extends StatefulWidget {
  const FindAndReplaceMenuWidget({
    super.key,
    required this.onDismiss,
    required this.editorState,
  });

  final EditorState editorState;
  final VoidCallback onDismiss;

  @override
  State<FindAndReplaceMenuWidget> createState() =>
      _FindAndReplaceMenuWidgetState();
}

class _FindAndReplaceMenuWidgetState extends State<FindAndReplaceMenuWidget> {
  bool showReplaceMenu = false;

  late SearchServiceV3 searchService = SearchServiceV3(
    editorState: widget.editorState,
  );

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
              onShowReplace: (value) => setState(
                () => showReplaceMenu = value,
              ),
            ),
          ),
          showReplaceMenu
              ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8.0,
                  ),
                  child: ReplaceMenu(
                    editorState: widget.editorState,
                    searchService: searchService,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class FindMenu extends StatefulWidget {
  const FindMenu({
    super.key,
    required this.onDismiss,
    required this.editorState,
    required this.searchService,
    required this.onShowReplace,
  });

  final EditorState editorState;
  final VoidCallback onDismiss;
  final SearchServiceV3 searchService;
  final void Function(bool value) onShowReplace;

  @override
  State<FindMenu> createState() => _FindMenuState();
}

class _FindMenuState extends State<FindMenu> {
  late final FocusNode findTextFieldFocusNode;

  final findTextEditingController = TextEditingController();

  String queriedPattern = '';

  bool showReplaceMenu = false;
  bool caseSensitive = false;

  @override
  void initState() {
    super.initState();

    widget.searchService.matchWrappers.addListener(_setState);
    widget.searchService.currentSelectedIndex.addListener(_setState);

    findTextEditingController.addListener(_searchPattern);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      findTextFieldFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.searchService.matchWrappers.removeListener(_setState);
    widget.searchService.currentSelectedIndex.removeListener(_setState);
    widget.searchService.dispose();
    findTextEditingController.removeListener(_searchPattern);
    findTextEditingController.dispose();
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
          icon: showReplaceMenu
              ? FlowySvgs.drop_menu_show_s
              : FlowySvgs.drop_menu_hide_s,
          tooltipText: '',
          onPressed: () {
            widget.onShowReplace(!showReplaceMenu);
            setState(
              () => showReplaceMenu = !showReplaceMenu,
            );
          },
        ),
        const HSpace(4.0),
        // find text input
        SizedBox(
          width: 150,
          height: 30,
          child: FlowyFormTextInput(
            onFocusCreated: (focusNode) {
              findTextFieldFocusNode = focusNode;
            },
            textInputAction: TextInputAction.none,
            onEditingComplete: () => widget.searchService.navigateToMatch(),
            controller: findTextEditingController,
            hintText: LocaleKeys.findAndReplace_find.tr(),
            textAlign: TextAlign.left,
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
    widget.searchService.findAndHighlight(findTextEditingController.text);
    setState(() => queriedPattern = findTextEditingController.text);
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
    this.localizations,
  });

  final EditorState editorState;

  /// The localizations of the find and replace menu
  final FindReplaceLocalizations? localizations;

  final SearchServiceV3 searchService;

  @override
  State<ReplaceMenu> createState() => _ReplaceMenuState();
}

class _ReplaceMenuState extends State<ReplaceMenu> {
  late final FocusNode replaceTextFieldFocusNode;
  final replaceTextEditingController = TextEditingController();

  @override
  void dispose() {
    replaceTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // placeholder for aligning the replace menu
        const HSpace(30),
        SizedBox(
          width: 150,
          height: 30,
          child: FlowyFormTextInput(
            onFocusCreated: (focusNode) {
              replaceTextFieldFocusNode = focusNode;
            },
            textInputAction: TextInputAction.none,
            onEditingComplete: () => widget.searchService.navigateToMatch(),
            controller: replaceTextEditingController,
            hintText: LocaleKeys.findAndReplace_replace.tr(),
            textAlign: TextAlign.left,
          ),
        ),
        const HSpace(4.0),
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
            replaceTextEditingController.text,
          ),
        ),
      ],
    );
  }

  void _replaceSelectedWord() {
    widget.searchService.replaceSelectedWord(replaceTextEditingController.text);
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
