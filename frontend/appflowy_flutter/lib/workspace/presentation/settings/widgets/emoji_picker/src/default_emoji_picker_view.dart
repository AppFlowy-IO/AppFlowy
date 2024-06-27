import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';

import 'emoji_picker.dart';
import 'emoji_picker_builder.dart';
import 'models/emoji_category_models.dart';
import 'models/emoji_model.dart';

class DefaultEmojiPickerView extends EmojiPickerBuilder {
  const DefaultEmojiPickerView(
    super.config,
    super.state, {
    super.key,
  });

  @override
  DefaultEmojiPickerViewState createState() => DefaultEmojiPickerViewState();
}

class DefaultEmojiPickerViewState extends State<DefaultEmojiPickerView>
    with TickerProviderStateMixin {
  PageController? _pageController;
  TabController? _tabController;
  final TextEditingController _emojiController = TextEditingController();
  final FocusNode _emojiFocusNode = FocusNode();
  EmojiCategoryGroup searchEmojiList =
      EmojiCategoryGroup(EmojiCategory.SEARCH, <Emoji>[]);
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    int initCategory = widget.state.emojiCategoryGroupList.indexWhere(
      (el) => el.category == widget.config.initCategory,
    );
    if (initCategory == -1) {
      initCategory = 0;
    }
    _tabController = TabController(
      initialIndex: initCategory,
      length: widget.state.emojiCategoryGroupList.length,
      vsync: this,
    );
    _pageController = PageController(initialPage: initCategory);
    _emojiFocusNode.requestFocus();
    _emojiController.addListener(() {
      final String query = _emojiController.text.toLowerCase();
      if (query.isEmpty) {
        searchEmojiList.emoji.clear();
        _pageController!.jumpToPage(_tabController!.index);
      } else {
        searchEmojiList.emoji.clear();
        for (final element in widget.state.emojiCategoryGroupList) {
          searchEmojiList.emoji.addAll(
            element.emoji
                .where((item) => item.name.toLowerCase().contains(query))
                .toList(),
          );
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _emojiFocusNode.dispose();
    _pageController?.dispose();
    _tabController?.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Widget _buildBackspaceButton() {
    if (widget.state.onBackspacePressed != null) {
      return Material(
        type: MaterialType.transparency,
        child: IconButton(
          padding: const EdgeInsets.only(bottom: 2),
          icon: Icon(Icons.backspace, color: widget.config.backspaceColor),
          onPressed: () => widget.state.onBackspacePressed!(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool isEmojiSearching() =>
      searchEmojiList.emoji.isNotEmpty || _emojiController.text.isNotEmpty;

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
                          ? [_buildCategory(EmojiCategory.SEARCH, emojiSize)]
                          : widget.state.emojiCategoryGroupList
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
                      : widget.state.emojiCategoryGroupList.length,
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final EmojiCategoryGroup emojiCategoryGroup =
                        isEmojiSearching()
                            ? searchEmojiList
                            : widget.state.emojiCategoryGroupList[index];
                    return _buildPage(emojiSize, emojiCategoryGroup);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategory(EmojiCategory category, double categorySize) {
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
      return InkWell(onTap: onPressed, child: child);
    }
    return GestureDetector(onTap: onPressed, child: child);
  }

  Widget _buildPage(double emojiSize, EmojiCategoryGroup emojiCategoryGroup) {
    // Display notice if recent has no entries yet
    if (emojiCategoryGroup.category == EmojiCategory.RECENT &&
        emojiCategoryGroup.emoji.isEmpty) {
      return _buildNoRecent();
    } else if (emojiCategoryGroup.category == EmojiCategory.SEARCH &&
        emojiCategoryGroup.emoji.isEmpty) {
      return Center(child: Text(widget.config.noEmojiFoundText));
    }
    // Build page normally
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: scrollController,
      barSize: 4.0,
      scrollbarPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      handleColor: widget.config.scrollBarHandleColor,
      showTrack: true,
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
          itemCount: emojiCategoryGroup.emoji.length,
          itemBuilder: (context, index) {
            final item = emojiCategoryGroup.emoji[index];
            return _buildEmoji(emojiSize, emojiCategoryGroup, item);
          },
          cacheExtent: 10,
        ),
      ),
    );
  }

  Widget _buildEmoji(
    double emojiSize,
    EmojiCategoryGroup emojiCategoryGroup,
    Emoji emoji,
  ) {
    return _buildButtonWidget(
      onPressed: () {
        widget.state.onEmojiSelected(emojiCategoryGroup.category, emoji);
      },
      child: FlowyHover(
        child: FittedBox(
          child: Text(
            emoji.emoji,
            style: TextStyle(fontSize: emojiSize),
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
