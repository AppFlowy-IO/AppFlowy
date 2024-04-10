import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_item_list_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_language_screen.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:go_router/go_router.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:highlight/languages/all.dart';
import 'package:provider/provider.dart';

import 'code_block_themes.dart';

final supportedLanguages = [
  'Assembly',
  'Bash',
  'BASIC',
  'C',
  'C#',
  'CPP',
  'Clojure',
  'CS',
  'CSS',
  'Dart',
  'Docker',
  'Elixir',
  'Elm',
  'Erlang',
  'Fortran',
  'Go',
  'GraphQL',
  'Haskell',
  'HTML',
  'Java',
  'JavaScript',
  'JSON',
  'Kotlin',
  'LaTeX',
  'Lisp',
  'Lua',
  'Markdown',
  'MATLAB',
  'Objective-C',
  'OCaml',
  'Perl',
  'PHP',
  'PowerShell',
  'Python',
  'R',
  'Ruby',
  'Rust',
  'Scala',
  'Shell',
  'SQL',
  'Swift',
  'TypeScript',
  'Visual Basic',
  'XML',
  'YAML',
];

final codeBlockSupportedLanguages = supportedLanguages
    .map((e) => e.toLowerCase())
    .toSet()
    .intersection(allLanguages.keys.toSet())
    .toList()
  ..add('auto')
  ..add('c')
  ..sort();

class CodeBlockKeys {
  const CodeBlockKeys._();

  static const String type = 'code';

  /// The content of a code block.
  ///
  /// The value is a String.
  static const String delta = 'delta';

  /// The language of a code block.
  ///
  /// The value is a String.
  static const String language = 'language';
}

Node codeBlockNode({
  Delta? delta,
  String? language,
}) {
  final attributes = {
    CodeBlockKeys.delta: (delta ?? Delta()).toJson(),
    CodeBlockKeys.language: language,
  };
  return Node(
    type: CodeBlockKeys.type,
    attributes: attributes,
  );
}

// defining the callout block menu item for selection
SelectionMenuItem codeBlockItem = SelectionMenuItem.node(
  getName: LocaleKeys.document_selectionMenu_codeBlock.tr,
  iconData: Icons.abc,
  keywords: ['code', 'codeblock'],
  nodeBuilder: (editorState, _) => codeBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

const _interceptorKey = 'code-block-interceptor';

class CodeBlockComponentBuilder extends BlockComponentBuilder {
  CodeBlockComponentBuilder({
    super.configuration,
    this.padding = const EdgeInsets.all(0),
  });

  final EdgeInsets padding;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CodeBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      padding: padding,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) => node.delta != null;
}

class CodeBlockComponentWidget extends BlockComponentStatefulWidget {
  const CodeBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.padding = const EdgeInsets.all(0),
  });

  final EdgeInsets padding;

  @override
  State<CodeBlockComponentWidget> createState() =>
      _CodeBlockComponentWidgetState();
}

class _CodeBlockComponentWidgetState extends State<CodeBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin {
  // the key used to forward focus to the richtext child
  @override
  final forwardKey = GlobalKey(debugLabel: 'code_flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey =
      GlobalKey(debugLabel: CodeBlockKeys.type);

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => node.key;

  @override
  Node get node => widget.node;

  @override
  late final editorState = context.read<EditorState>();

  final popoverController = PopoverController();
  final scrollController = ScrollController();

  // We use this to calculate the position of the cursor in the code block
  // for automatic scrolling.
  final codeBlockKey = GlobalKey();

  String? get language => node.attributes[CodeBlockKeys.language] as String?;
  String? autoDetectLanguage;

  bool isSelected = false;
  bool isHovering = false;
  bool canPanStart = true;

  late final interceptor = SelectionGestureInterceptor(
    key: _interceptorKey,
    canTap: (_) => canPanStart && !isSelected,
    canPanStart: (_) => canPanStart && !isSelected,
  );

  late final StreamSubscription<(TransactionTime, Transaction)>
      transactionSubscription;

  @override
  void initState() {
    super.initState();
    editorState.selectionService.registerGestureInterceptor(interceptor);
    editorState.selectionNotifier.addListener(calculateScrollPosition);
    transactionSubscription = editorState.transactionStream.listen((event) {
      if (event.$2.operations.any((op) => op.path.equals(node.path))) {
        calculateScrollPosition();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    editorState.selectionService.currentSelection
        .removeListener(calculateScrollPosition);
    editorState.selectionService.unregisterGestureInterceptor(_interceptorKey);
    transactionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    Widget child = MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          color: AFThemeExtension.of(context).calloutBGColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          textDirection: textDirection,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => canPanStart = false),
              onExit: (_) => setState(() => canPanStart = true),
              child: Opacity(
                opacity: isHovering || isSelected ? 1.0 : 0.0,
                child: Row(
                  children: [
                    _LanguageSelector(
                      controller: popoverController,
                      language: language,
                      isSelected: isSelected,
                      onLanguageSelected: updateLanguage,
                      onMenuOpen: () => isSelected = true,
                      onMenuClose: () => setState(() => isSelected = false),
                    ),
                    const Spacer(),
                    _CopyButton(node: node),
                  ],
                ),
              ),
            ),
            _buildCodeBlock(context, textDirection),
          ],
        ),
      ),
    );

    child = Padding(key: blockComponentKey, padding: padding, child: child);

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );

    if (PlatformExtension.isDesktopOrWeb) {
      if (widget.showActions && widget.actionBuilder != null) {
        child = BlockComponentActionWrapper(
          node: widget.node,
          actionBuilder: widget.actionBuilder!,
          child: child,
        );
      }
    } else {
      // show a fixed menu on mobile
      child = MobileBlockActionButtons(
        node: node,
        editorState: editorState,
        child: child,
      );
    }

    return child;
  }

  Widget _buildCodeBlock(BuildContext context, TextDirection textDirection) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final delta = node.delta ?? Delta();
    final content = delta.toPlainText();

    final result = highlight.highlight.parse(
      content,
      language: language,
      autoDetection: language == null,
    );

    autoDetectLanguage = language ?? result.language;

    final codeNodes = result.nodes;
    if (codeNodes == null) {
      throw Exception('Code block parse error.');
    }

    final codeTextSpans = _convert(codeNodes, isLightMode: isLightMode);
    final linesOfCode = delta.toPlainText().split('\n').length;

    return Padding(
      padding: widget.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LinesOfCodeNumbers(
            linesOfCode: linesOfCode,
            textStyle: textStyle,
          ),
          Flexible(
            child: SingleChildScrollView(
              key: codeBlockKey,
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: AppFlowyRichText(
                key: forwardKey,
                delegate: this,
                node: widget.node,
                editorState: editorState,
                placeholderText: placeholderText,
                lineHeight: 1.5,
                textSpanDecorator: (_) => TextSpan(
                  style: textStyle,
                  children: codeTextSpans,
                ),
                placeholderTextSpanDecorator: (textSpan) => textSpan,
                textDirection: textDirection,
                cursorColor: editorState.editorStyle.cursorColor,
                selectionColor: editorState.editorStyle.selectionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateLanguage(String language) async {
    final transaction = editorState.transaction
      ..updateNode(
        node,
        {CodeBlockKeys.language: language == 'auto' ? null : language},
      );
    await editorState.apply(transaction);
  }

  void calculateScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selection = editorState.selection;
      if (!mounted || selection == null || !selection.isCollapsed) {
        return;
      }

      final nodes = editorState.getNodesInSelection(selection);
      if (nodes.isEmpty || nodes.length > 1) {
        return;
      }

      final selectedNode = nodes.first;
      if (selectedNode.path.equals(widget.node.path)) {
        final renderBox =
            codeBlockKey.currentContext?.findRenderObject() as RenderBox?;
        final rects = editorState.selectionRects();
        if (renderBox == null || rects.isEmpty) {
          return;
        }

        final codeBlockOffset = renderBox.localToGlobal(Offset.zero);
        final codeBlockSize = renderBox.size;

        final cursorRect = rects.first;
        final cursorRelativeOffset = cursorRect.center - codeBlockOffset;

        // If the relative position of the cursor is less than 1, and the scrollController
        // is not at offset 0, then we need to scroll to the left to make cursor visible.
        if (cursorRelativeOffset.dx < 1 && scrollController.offset > 0) {
          scrollController
              .jumpTo(scrollController.offset + cursorRelativeOffset.dx - 1);

          // If the relative position of the cursor is greater than the width of the code block,
          // then we need to scroll to the right to make cursor visible.
        } else if (cursorRelativeOffset.dx > codeBlockSize.width - 1) {
          scrollController.jumpTo(
            scrollController.offset +
                cursorRelativeOffset.dx -
                codeBlockSize.width +
                1,
          );
        }
      }
    });
  }

  // Copy from flutter.highlight package.
  // https://github.com/git-touch/highlight.dart/blob/master/flutter_highlight/lib/flutter_highlight.dart
  List<TextSpan> _convert(
    List<highlight.Node> nodes, {
    bool isLightMode = true,
  }) {
    final List<TextSpan> spans = [];
    List<TextSpan> currentSpans = spans;
    final List<List<TextSpan>> stack = [];

    final codeblockTheme =
        isLightMode ? lightThemeInCodeblock : darkThemeInCodeBlock;

    void traverse(highlight.Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(
                  text: node.value,
                  style: codeblockTheme[node.className!],
                ),
        );
      } else if (node.children != null) {
        final List<TextSpan> tmp = [];
        currentSpans.add(
          TextSpan(
            children: tmp,
            style: codeblockTheme[node.className!],
          ),
        );
        stack.add(currentSpans);
        currentSpans = tmp;

        for (final n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (final node in nodes) {
      traverse(node);
    }

    return spans;
  }
}

class _LinesOfCodeNumbers extends StatelessWidget {
  const _LinesOfCodeNumbers({
    required this.linesOfCode,
    required this.textStyle,
  });

  final int linesOfCode;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 1; i <= linesOfCode; i++)
            Text(
              i.toString(),
              style: textStyle.copyWith(
                color: AFThemeExtension.of(context).textColor.withAlpha(155),
              ),
            ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.node});

  final Node node;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FlowyTooltip(
        message: LocaleKeys.document_codeBlock_copyTooltip.tr(),
        child: FlowyIconButton(
          onPressed: () async {
            await getIt<ClipboardService>().setData(
              ClipboardServiceData(
                plainText: node.delta?.toPlainText(),
              ),
            );

            if (context.mounted) {
              showSnackBarMessage(
                context,
                LocaleKeys.document_codeBlock_codeCopiedSnackbar.tr(),
              );
            }
          },
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          icon: FlowySvg(
            FlowySvgs.copy_s,
            color: AFThemeExtension.of(context).textColor,
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatefulWidget {
  const _LanguageSelector({
    required this.controller,
    this.language,
    required this.isSelected,
    required this.onLanguageSelected,
    this.onMenuOpen,
    this.onMenuClose,
  });

  final PopoverController controller;
  final String? language;
  final bool isSelected;
  final void Function(String) onLanguageSelected;
  final VoidCallback? onMenuOpen;
  final VoidCallback? onMenuClose;

  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
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
            fontColor: Theme.of(context).colorScheme.onBackground,
            fillColor: widget.isSelected
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
            onPressed: () async {
              if (PlatformExtension.isMobile) {
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

    if (PlatformExtension.isDesktopOrWeb) {
      child = AppFlowyPopover(
        controller: widget.controller,
        direction: PopoverDirection.bottomWithLeftAligned,
        onOpen: widget.onMenuOpen,
        constraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
        onClose: widget.onMenuClose,
        popupBuilder: (_) => _LanguageSelectionPopover(
          editorState: context.read<EditorState>(),
          language: widget.language,
          onLanguageSelected: (language) {
            widget.onLanguageSelected(language);
            widget.controller.close();
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
    required this.onLanguageSelected,
  });

  final EditorState editorState;
  final String? language;
  final void Function(String) onLanguageSelected;

  @override
  State<_LanguageSelectionPopover> createState() =>
      _LanguageSelectionPopoverState();
}

class _LanguageSelectionPopoverState extends State<_LanguageSelectionPopover> {
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  List<String> supportedLanguages =
      codeBlockSupportedLanguages.map((e) => e.capitalize()).toList();
  late int selectedIndex = supportedLanguages.indexOf(widget.language ?? '');

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyTextField(
          focusNode: focusNode,
          autoFocus: false,
          controller: searchController,
          hintText: LocaleKeys.document_codeBlock_searchLanguageHint.tr(),
          onChanged: (_) => setState(() {
            supportedLanguages = codeBlockSupportedLanguages
                .where((e) => e.contains(searchController.text.toLowerCase()))
                .map((e) => e.capitalize())
                .toList();
            selectedIndex =
                codeBlockSupportedLanguages.indexOf(widget.language ?? '');
          }),
        ),
        const VSpace(8),
        Flexible(
          child: SelectableItemListMenu(
            shrinkWrap: true,
            items: supportedLanguages,
            selectedIndex: selectedIndex,
            onSelected: (index) =>
                widget.onLanguageSelected(supportedLanguages[index]),
          ),
        ),
      ],
    );
  }
}
