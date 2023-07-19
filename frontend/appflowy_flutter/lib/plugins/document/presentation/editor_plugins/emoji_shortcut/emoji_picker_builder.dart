import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/config.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/emoji_picker_builder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/emoji_view_state.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/models/category_models.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/models/emoji_model.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShortcutEmojiPickerView extends EmojiPickerBuilder {
  final EditorState editorState;
  final VoidCallback onExit;

  const ShortcutEmojiPickerView(
    Config config,
    EmojiViewState state,
    this.editorState,
    this.onExit, {
    Key? key,
  }) : super(config, state, key: key);

  @override
  ShortcutEmojiPickerViewState createState() => ShortcutEmojiPickerViewState();
}

@visibleForTesting
class ShortcutEmojiPickerViewState extends State<ShortcutEmojiPickerView>
    with TickerProviderStateMixin {
  PageController? _pageController;
  TabController? _tabController;
  final TextEditingController _emojiController = TextEditingController();
  final FocusNode _emojiFocusNode = FocusNode();
  CategoryEmoji searchEmojiList = CategoryEmoji(Category.SEARCH, <Emoji>[]);
  final _focusNode = FocusNode(debugLabel: 'popup_list_widget');
  int _selectedIndex = 0;
  final Color selectedItemColor = const Color(0xFFE0F8FF);
  final resultsFilterCount = 35;

  @override
  void initState() {
    var initCategory = widget.state.categoryEmoji.indexWhere(
      (element) => element.category == widget.config.initCategory,
    );
    if (initCategory == -1) {
      initCategory = 0;
    }
    _tabController = TabController(
      initialIndex: initCategory,
      length: widget.state.categoryEmoji.length,
      vsync: this,
    );
    _pageController = PageController(initialPage: initCategory);
    _emojiFocusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    super.initState();
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _emojiFocusNode.dispose();
    super.dispose();
  }

  bool isEmojiSearching() {
    final bool result =
        searchEmojiList.emoji.isNotEmpty || _emojiController.text.isNotEmpty;

    return result;
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    final CategoryEmoji catEmoji = isEmojiSearching()
        ? searchEmojiList
        : widget.state.categoryEmoji[_tabController!.index];

    final List<Emoji> showingItems = catEmoji.emoji;
    Log.keyboard.debug('colon command, on key $event');
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final arrowKeys = [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown
    ];

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_emojiController.text.isEmpty) {
        widget.onExit();
        return KeyEventResult.ignored;
      }
      if (showingItems.isEmpty) {
        return KeyEventResult.handled;
      }
      for (int i = 0; i < _emojiController.text.length + 1; i++) {
        _deleteLastCharacters();
      }
      widget.state.onEmojiSelected(
        Category.SEARCH,
        showingItems[_selectedIndex],
      );
      widget.onExit();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onExit();

      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      if (_emojiController.text.isEmpty) {
        widget.onExit();
      }
      return KeyEventResult.ignored;
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_emojiController.text.isEmpty) {
        widget.onExit();
      } else {
        _emojiController.text = _emojiController.text
            .substring(0, _emojiController.text.length - 1);
        _searchEmoji();
      }
      _deleteLastCharacters();
      return KeyEventResult.handled;
    } else if (event.character != null &&
        !arrowKeys.contains(event.logicalKey) &&
        event.logicalKey != LogicalKeyboardKey.tab) {
      _emojiController.text += event.character!;
      _searchEmoji();
      _insertText(event.character!);
      return KeyEventResult.handled;
    }

    var newSelectedIndex = _selectedIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      newSelectedIndex -= 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      newSelectedIndex += 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      newSelectedIndex -= 7;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      newSelectedIndex += 7;
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      newSelectedIndex += 7;
      final currRow = (newSelectedIndex) % 7;
      if (newSelectedIndex >= showingItems.length) {
        newSelectedIndex = (currRow + 1) % 7;
      }
    }

    if (newSelectedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newSelectedIndex.clamp(0, showingItems.length - 1);
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  _searchEmoji() {
    final String query = _emojiController.text.toLowerCase();

    searchEmojiList.emoji.clear();
    for (final element in widget.state.categoryEmoji) {
      searchEmojiList.emoji.addAll(
        element.emoji.where((item) {
          return item.name.toLowerCase().replaceAll(" ", "_").contains(query);
        }).toList(),
      );
      searchEmojiList.emoji =
          searchEmojiList.emoji.take(resultsFilterCount).toList();
    }
    setState(() {});
  }

  void _deleteLastCharacters({int length = 1}) {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = widget.editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    // widget.onSelectionUpdate();
    final transaction = widget.editorState.transaction
      ..deleteText(
        node,
        selection.start.offset - length,
        length,
      );
    widget.editorState.apply(transaction);
  }

  void _insertText(String text) {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isSingle) {
      return;
    }
    final node = widget.editorState.getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final transaction = widget.editorState.transaction
      ..insertText(
        node,
        selection.end.offset,
        text,
      );
    widget.editorState.apply(transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final emojiSize = widget.config.getEmojiSize(constraints.maxWidth);
          return Visibility(
            visible: _emojiController.text.isNotEmpty,
            child: Container(
              color: widget.config.bgColor,
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Flexible(
                    child: PageView.builder(
                      itemCount: searchEmojiList.emoji.isNotEmpty
                          ? 1
                          : widget.state.categoryEmoji.length,
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        _tabController!.animateTo(
                          index,
                          duration: widget.config.tabIndicatorAnimDuration,
                        );
                      },
                      itemBuilder: (context, index) {
                        final CategoryEmoji catEmoji = isEmojiSearching()
                            ? searchEmojiList
                            : widget.state.categoryEmoji[index];

                        return _buildPage(emojiSize, catEmoji);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonWidget({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    if (widget.config.buttonMode == ButtonMode.MATERIAL) {
      return InkWell(
        onTap: onPressed,
        child: child,
      );
    }
    return GestureDetector(
      onTap: onPressed,
      child: child,
    );
  }

  Widget _buildPage(double emojiSize, CategoryEmoji categoryEmoji) {
    // Display notice if recent has no entries yet
    final scrollController = ScrollController();

    if (categoryEmoji.category == Category.RECENT &&
        categoryEmoji.emoji.isEmpty) {
      return _buildNoRecent();
    } else if (categoryEmoji.category == Category.SEARCH &&
        categoryEmoji.emoji.isEmpty) {
      return const Center(child: Text("No Emoji Found"));
    }
    // Build page normally
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: scrollController,
      barSize: 4.0,
      scrollbarPadding: const EdgeInsets.symmetric(horizontal: 5.0),
      handleColor: const Color(0xffDFE0E0),
      trackColor: const Color(0xffDFE0E0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.config.columns,
            mainAxisSpacing: widget.config.verticalSpacing,
            crossAxisSpacing: widget.config.horizontalSpacing,
          ),
          itemCount: categoryEmoji.emoji.length,
          itemBuilder: (context, index) {
            final item = categoryEmoji.emoji[index];
            return _buildEmoji(
              emojiSize,
              categoryEmoji,
              item,
              index == _selectedIndex,
            );
          },
          cacheExtent: 10,
        ),
      ),
    );
  }

  Widget _buildEmoji(
    double emojiSize,
    CategoryEmoji categoryEmoji,
    Emoji emoji,
    bool isSelected,
  ) {
    return _buildButtonWidget(
      onPressed: () {
        widget.state.onEmojiSelected(categoryEmoji.category, emoji);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: Corners.s8Border,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            emoji.emoji,
            textScaleFactor: 1.0,
            style: TextStyle(
              fontSize: emojiSize,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoRecent() {
    return Center(
      child: Text(
        widget.config.noRecentsText,
        style: widget.config.noRecentsStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
