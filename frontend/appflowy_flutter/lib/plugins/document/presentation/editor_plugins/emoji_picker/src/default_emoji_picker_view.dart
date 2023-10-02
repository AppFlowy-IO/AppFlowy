import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'emji_picker_config.dart';
import 'emoji_picker.dart';
import 'emoji_picker_builder.dart';
import 'emoji_view_state.dart';
import 'models/category_models.dart';
import 'models/emoji_model.dart';

class DefaultEmojiPickerView extends EmojiPickerBuilder {
  const DefaultEmojiPickerView(
    EmojiPickerConfig config,
    EmojiViewState state, {
    Key? key,
  }) : super(config, state, key: key);

  @override
  DefaultEmojiPickerViewState createState() => DefaultEmojiPickerViewState();
}

class DefaultEmojiPickerViewState extends State<DefaultEmojiPickerView>
    with TickerProviderStateMixin {
  PageController? _pageController;
  TabController? _tabController;
  final TextEditingController _emojiController = TextEditingController();
  final FocusNode _emojiFocusNode = FocusNode();
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
    _pageController?.dispose();
    _tabController?.dispose();
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
        final style = Theme.of(context);

        return Container(
          color: widget.config.bgColor,
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              const VSpace(4),
              // search bar
              SizedBox(
                height: 32.0,
                child: TextField(
                  controller: _emojiController,
                  focusNode: _emojiFocusNode,
                  autofocus: true,
                  style: style.textTheme.bodyMedium,
                  cursorColor: style.textTheme.bodyMedium?.color,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8),
                    hintText: widget.config.searchHintText,
                    hintStyle: widget.config.serachHintTextStyle,
                    enabledBorder: widget.config.serachBarEnableBorder,
                    focusedBorder: widget.config.serachBarFocusedBorder,
                  ),
                ),
              ),
              const VSpace(4),
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      labelColor: widget.config.selectedCategoryIconColor,
                      unselectedLabelColor: widget.config.categoryIconColor,
                      controller: isEmojiSearching()
                          ? TabController(length: 1, vsync: this)
                          : _tabController,
                      labelPadding: EdgeInsets.zero,
                      indicatorColor:
                          widget.config.selectedCategoryIconBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      indicator: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(4.0),
                        color: style.colorScheme.secondary,
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
      return Center(child: Text(widget.config.noEmojiFoundText));
    }
    // Build page normally
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: scrollController,
      barSize: 4.0,
      scrollbarPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      handleColor: widget.config.scrollBarHandleColor,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.config.emojiNumberPerRow,
            mainAxisSpacing: widget.config.verticalSpacing,
            crossAxisSpacing: widget.config.horizontalSpacing,
          ),
          itemCount: categoryEmoji.emoji.length,
          itemBuilder: (context, index) {
            final item = categoryEmoji.emoji[index];
            return _buildEmoji(emojiSize, categoryEmoji, item);
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
  ) {
    return _buildButtonWidget(
      onPressed: () {
        widget.state.onEmojiSelected(categoryEmoji.category, emoji);
      },
      child: FlowyHover(
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
