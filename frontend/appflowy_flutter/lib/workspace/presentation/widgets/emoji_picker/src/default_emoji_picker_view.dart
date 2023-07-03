import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models/category_models.dart';
import 'config.dart';
import 'models/emoji_model.dart';
import 'emoji_picker.dart';
import 'emoji_picker_builder.dart';
import 'emoji_view_state.dart';

class DefaultEmojiPickerView extends EmojiPickerBuilder {
  const DefaultEmojiPickerView(Config config, EmojiViewState state, {Key? key})
      : super(config, state, key: key);

  @override
  DefaultEmojiPickerViewState createState() => DefaultEmojiPickerViewState();
}

class DefaultEmojiPickerViewState extends State<DefaultEmojiPickerView>
    with TickerProviderStateMixin {
  PageController? _pageController;
  TabController? _tabController;
  final TextEditingController _emojiController = TextEditingController();
  final FocusNode _emojiFocusNode = FocusNode();
  final CategoryEmoji _categoryEmoji =
      CategoryEmoji(Category.SEARCH, List.empty(growable: true));
  CategoryEmoji searchEmojiList = CategoryEmoji(Category.SEARCH, <Emoji>[]);

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

    _emojiController.addListener(() {
      final String query = _emojiController.text.toLowerCase();
      if (query.isEmpty) {
        searchEmojiList.emoji.clear();
        _pageController!.jumpToPage(
          _tabController!.index,
        );
      } else {
        searchEmojiList.emoji.clear();
        for (final element in widget.state.categoryEmoji) {
          searchEmojiList.emoji.addAll(
            element.emoji.where((item) {
              return item.name.toLowerCase().contains(query);
            }).toList(),
          );
        }
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _emojiFocusNode.dispose();
    super.dispose();
  }

  Widget _buildBackspaceButton() {
    if (widget.state.onBackspacePressed != null) {
      return Material(
        type: MaterialType.transparency,
        child: IconButton(
          padding: const EdgeInsets.only(bottom: 2),
          icon: Icon(
            Icons.backspace,
            color: widget.config.backspaceColor,
          ),
          onPressed: () {
            widget.state.onBackspacePressed!();
          },
        ),
      );
    }
    return Container();
  }

  bool isEmojiSearching() {
    final bool result =
        searchEmojiList.emoji.isNotEmpty || _emojiController.text.isNotEmpty;

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emojiSize = widget.config.getEmojiSize(constraints.maxWidth);

        return Container(
          color: widget.config.bgColor,
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _emojiController,
                  focusNode: _emojiFocusNode,
                  autofocus: true,
                  cursorWidth: 1.0,
                  cursorColor: Theme.of(context).colorScheme.tertiary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w400,
                      ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    hintText: "Search emoji",
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary,
                        width: 2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                ),
              ),
              const VSpace(6),
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      labelColor: widget.config.iconColorSelected,
                      unselectedLabelColor: widget.config.iconColor,
                      controller: isEmojiSearching()
                          ? TabController(length: 1, vsync: this)
                          : _tabController,
                      labelPadding: EdgeInsets.zero,
                      indicatorColor: widget.config.indicatorColor,
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        color: widget.config.selectedHoverColor,
                      ),
                      onTap: (index) {
                        _pageController!.animateToPage(
                          index,
                          duration: widget.config.tabIndicatorAnimDuration,
                          curve: Curves.ease,
                        );
                      },
                      tabs: isEmojiSearching()
                          ? [_buildCategory(Category.SEARCH, emojiSize)]
                          : widget.state.categoryEmoji
                              .asMap()
                              .entries
                              .map<Widget>(
                                (item) => _buildCategory(
                                  item.value.category,
                                  emojiSize,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  _buildBackspaceButton(),
                ],
              ),
              Flexible(
                child: PageView.builder(
                  itemCount: searchEmojiList.emoji.isNotEmpty
                      ? 1
                      : widget.state.categoryEmoji.length,
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  // onPageChanged: (index) {
                  //   _tabController!.animateTo(
                  //     index,
                  //     duration: widget.config.tabIndicatorAnimDuration,
                  //   );
                  // },
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
        );
      },
    );
  }

  Widget _buildCategory(Category category, double categorySize) {
    return Tab(
      height: categorySize,
      child: Icon(
        widget.config.getIconForCategory(category),
        size: categorySize / 1.3,
      ),
    );
  }

  Widget _buildButtonWidget({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    if (widget.config.buttonMode == ButtonMode.MATERIAL) {
      return TextButton(
        onPressed: onPressed,
        style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.zero)),
        child: child,
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
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
        child: GridView.count(
          scrollDirection: Axis.vertical,
          physics: const ScrollPhysics(),
          controller: scrollController,
          shrinkWrap: true,
          // primary: true,
          padding: const EdgeInsets.all(0),
          crossAxisCount: widget.config.columns,
          mainAxisSpacing: widget.config.verticalSpacing,
          crossAxisSpacing: widget.config.horizontalSpacing,
          children: _categoryEmoji.emoji.isNotEmpty
              ? _categoryEmoji.emoji
                  .map<Widget>((e) => _buildEmoji(emojiSize, categoryEmoji, e))
                  .toList()
              : categoryEmoji.emoji
                  .map<Widget>(
                    (item) => _buildEmoji(emojiSize, categoryEmoji, item),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildEmoji(
    double emojiSize,
    CategoryEmoji categoryEmoji,
    Emoji emoji,
  ) {
    return _buildButtonWidget(
      onPressed: () {
        widget.state.onEmojiSelected(categoryEmoji.category, emoji);
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          emoji.emoji,
          textScaleFactor: 1.0,
          style: TextStyle(
            fontSize: emojiSize,
            backgroundColor: Colors.transparent,
            color: Theme.of(context).iconTheme.color,
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
