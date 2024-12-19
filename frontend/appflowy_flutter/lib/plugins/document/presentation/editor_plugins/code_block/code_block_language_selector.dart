import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_item_list_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_language_screen.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:universal_platform/universal_platform.dart';

CodeBlockLanguagePickerBuilder codeBlockLanguagePickerBuilder = (
  editorState,
  supportedLanguages,
  onLanguageSelected, {
  selectedLanguage,
  onMenuClose,
  onMenuOpen,
}) =>
    CodeBlockLanguageSelector(
      editorState: editorState,
      language: selectedLanguage,
      supportedLanguages: supportedLanguages,
      onLanguageSelected: onLanguageSelected,
      onMenuClose: onMenuClose,
      onMenuOpen: onMenuOpen,
    );

class CodeBlockLanguageSelector extends StatefulWidget {
  const CodeBlockLanguageSelector({
    super.key,
    required this.editorState,
    required this.supportedLanguages,
    this.language,
    required this.onLanguageSelected,
    this.onMenuOpen,
    this.onMenuClose,
  });

  final EditorState editorState;
  final List<String> supportedLanguages;
  final String? language;
  final void Function(String) onLanguageSelected;
  final VoidCallback? onMenuOpen;
  final VoidCallback? onMenuClose;

  @override
  State<CodeBlockLanguageSelector> createState() =>
      _CodeBlockLanguageSelectorState();
}

class _CodeBlockLanguageSelectorState extends State<CodeBlockLanguageSelector> {
  final controller = PopoverController();

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: FlowyTextButton(
            widget.language?.capitalize() ??
                LocaleKeys.document_codeBlock_language_auto.tr(),
            constraints: const BoxConstraints(minWidth: 50),
            fontColor: AFThemeExtension.of(context).onBackground,
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
            fillColor: Colors.transparent,
            hoverColor: Theme.of(context).colorScheme.secondaryContainer,
            onPressed: () async {
              if (UniversalPlatform.isMobile) {
                final language = await context
                    .push<String>(MobileCodeLanguagePickerScreen.routeName);
                if (language != null) {
                  widget.onLanguageSelected(language);
                }
              }
            },
          ),
        ),
      ],
    );

    if (UniversalPlatform.isDesktopOrWeb) {
      child = AppFlowyPopover(
        controller: controller,
        direction: PopoverDirection.bottomWithLeftAligned,
        onOpen: widget.onMenuOpen,
        constraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
        onClose: widget.onMenuClose,
        popupBuilder: (_) => _LanguageSelectionPopover(
          editorState: widget.editorState,
          language: widget.language,
          supportedLanguages: widget.supportedLanguages,
          onLanguageSelected: (language) {
            widget.onLanguageSelected(language);
            controller.close();
          },
        ),
        child: child,
      );
    }

    return child;
  }
}

class _LanguageSelectionPopover extends StatefulWidget {
  const _LanguageSelectionPopover({
    required this.editorState,
    required this.language,
    required this.supportedLanguages,
    required this.onLanguageSelected,
  });

  final EditorState editorState;
  final String? language;
  final List<String> supportedLanguages;
  final void Function(String) onLanguageSelected;

  @override
  State<_LanguageSelectionPopover> createState() =>
      _LanguageSelectionPopoverState();
}

class _LanguageSelectionPopoverState extends State<_LanguageSelectionPopover> {
  final searchController = TextEditingController();
  final focusNode = FocusNode();
  late List<String> filteredLanguages =
      widget.supportedLanguages.map((e) => e.capitalize()).toList();
  late int selectedIndex =
      widget.supportedLanguages.indexOf(widget.language?.toLowerCase() ?? '');
  final ItemScrollController languageListController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      // This is a workaround because longer taps might break the
      // focus, this might be an issue with the Flutter framework.
      (_) => Future.delayed(
        const Duration(milliseconds: 100),
        () => focusNode.requestFocus(),
      ),
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowUp):
            _DirectionIntent(AxisDirection.up),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _DirectionIntent(AxisDirection.down),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      child: Actions(
        actions: {
          _DirectionIntent: CallbackAction<_DirectionIntent>(
            onInvoke: (intent) => onArrowKey(intent.direction),
          ),
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (selectedIndex < 0) return;
              selectLanguage(selectedIndex);
              return null;
            },
          ),
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowyTextField(
              focusNode: focusNode,
              autoFocus: false,
              controller: searchController,
              hintText: LocaleKeys.document_codeBlock_searchLanguageHint.tr(),
              onChanged: (_) => setState(() {
                filteredLanguages = widget.supportedLanguages
                    .where(
                      (e) => e.contains(searchController.text.toLowerCase()),
                    )
                    .map((e) => e.capitalize())
                    .toList();
                selectedIndex =
                    widget.supportedLanguages.indexOf(widget.language ?? '');
              }),
            ),
            const VSpace(8),
            Flexible(
              child: SelectableItemListMenu(
                controller: languageListController,
                shrinkWrap: true,
                items: filteredLanguages,
                selectedIndex: selectedIndex,
                onSelected: selectLanguage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onArrowKey(AxisDirection direction) {
    if (filteredLanguages.isEmpty) return;
    final isUp = direction == AxisDirection.up;
    if (selectedIndex < 0) {
      selectedIndex = isUp ? 0 : -1;
    }
    final length = filteredLanguages.length;
    setState(() {
      if (isUp) {
        selectedIndex = selectedIndex == 0 ? length - 1 : selectedIndex - 1;
      } else {
        selectedIndex = selectedIndex == length - 1 ? 0 : selectedIndex + 1;
      }
    });
    languageListController.scrollTo(
      index: selectedIndex,
      alignment: 0.5,
      duration: const Duration(milliseconds: 300),
    );
  }

  void selectLanguage(int index) {
    widget.onLanguageSelected(filteredLanguages[index]);
  }
}

/// [ScrollIntent] is not working, so using this custom Intent
class _DirectionIntent extends Intent {
  const _DirectionIntent(this.direction);

  final AxisDirection direction;
}
