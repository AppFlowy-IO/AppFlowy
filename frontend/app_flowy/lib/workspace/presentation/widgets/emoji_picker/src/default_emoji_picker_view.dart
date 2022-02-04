import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'category_emoji.dart';
import 'config.dart';
import 'emoji.dart';
import 'emoji_picker.dart';
import 'emoji_picker_builder.dart';
import 'emoji_view_state.dart';

/// Default EmojiPicker Implementation
class DefaultEmojiPickerView extends EmojiPickerBuilder {
  /// Constructor
  DefaultEmojiPickerView(Config config, EmojiViewState state) : super(config, state);

  @override
  _DefaultEmojiPickerViewState createState() => _DefaultEmojiPickerViewState();
}

class _DefaultEmojiPickerViewState extends State<DefaultEmojiPickerView> with SingleTickerProviderStateMixin {
  PageController? _pageController;
  TabController? _tabController;
  final TextEditingController _emojiController = TextEditingController();
  final FocusNode _emojiFocusNode = FocusNode();
  final CategoryEmoji _categoryEmoji = CategoryEmoji(Category.SEARCH, List.empty(growable: true));
  List<CategoryEmoji> searchEmojiList = List.empty(growable: true);

  @override
  void initState() {
    var initCategory =
        widget.state.categoryEmoji.indexWhere((element) => element.category == widget.config.initCategory);
    if (initCategory == -1) {
      initCategory = 0;
    }
    _tabController = TabController(initialIndex: initCategory, length: widget.state.categoryEmoji.length, vsync: this);
    _pageController = PageController(initialPage: initCategory);
    _emojiFocusNode.requestFocus();
    _emojiController.addListener(() {
      //TODO @gaganyadav80: FIXIT: Search not working as expected.
      String query = _emojiController.text.toLowerCase();
      if (query.isEmpty) {
        searchEmojiList
          ..clear()
          ..addAll(widget.state.categoryEmoji);
      } else {
        searchEmojiList.clear();
        for (var element in widget.state.categoryEmoji) {
          searchEmojiList.add(
            CategoryEmoji(
                element.category,
                element.emoji.where((item) {
                  return item.name.toLowerCase().contains(query);
                }).toList()),
          );
        }

        print("$searchEmojiList");
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
            }),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emojiSize = widget.config.getEmojiSize(constraints.maxWidth);

        return Container(
          color: widget.config.bgColor,
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              SizedBox(
                height: 25.0,
                child: TextField(
                  controller: _emojiController,
                  focusNode: _emojiFocusNode,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14.0),
                  cursorWidth: 1.0,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 5.0),
                    hintText: "Search emoji",
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: const BorderSide(),
                      gapPadding: 0.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: const BorderSide(),
                      gapPadding: 0.0,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hoverColor: Colors.white,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      labelColor: widget.config.iconColorSelected,
                      unselectedLabelColor: widget.config.iconColor,
                      controller: _tabController,
                      labelPadding: EdgeInsets.zero,
                      indicatorColor: widget.config.indicatorColor,
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      indicator: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(4.0),
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      onTap: (index) {
                        _pageController!.animateToPage(
                          index,
                          duration: widget.config.tabIndicatorAnimDuration,
                          curve: Curves.ease,
                        );
                      },
                      tabs: widget.state.categoryEmoji
                          .asMap()
                          .entries
                          .map<Widget>((item) => _buildCategory(item.key, item.value.category, emojiSize))
                          .toList(),
                    ),
                  ),
                  _buildBackspaceButton(),
                ],
              ),
              Flexible(
                child: PageView.builder(
                  itemCount: searchEmojiList.isEmpty ? widget.state.categoryEmoji.length : searchEmojiList.length,
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    _tabController!.animateTo(
                      index,
                      duration: widget.config.tabIndicatorAnimDuration,
                    );
                  },
                  itemBuilder: (context, index) {
                    CategoryEmoji catEmoji =
                        searchEmojiList.isNotEmpty ? searchEmojiList[index] : widget.state.categoryEmoji[index];
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

  Widget _buildCategory(int index, Category category, double categorySize) {
    return Tab(
      height: categorySize,
      child: Icon(
        widget.config.getIconForCategory(category),
        size: categorySize / 1.3,
      ),
    );
  }

  Widget _buildButtonWidget({required VoidCallback onPressed, required Widget child}) {
    if (widget.config.buttonMode == ButtonMode.MATERIAL) {
      return TextButton(
        onPressed: onPressed,
        child: child,
        style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.zero)),
      );
    }
    return CupertinoButton(padding: EdgeInsets.zero, onPressed: onPressed, child: child);
  }

  Widget _buildPage(double emojiSize, CategoryEmoji categoryEmoji) {
    // Display notice if recent has no entries yet
    final scrollController = ScrollController();

    if (categoryEmoji.category == Category.RECENT && categoryEmoji.emoji.isEmpty) {
      return _buildNoRecent();
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
              ? _categoryEmoji.emoji.map<Widget>((e) => _buildEmoji(emojiSize, categoryEmoji, e)).toList()
              : categoryEmoji.emoji.map<Widget>((item) => _buildEmoji(emojiSize, categoryEmoji, item)).toList(),
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
          fit: BoxFit.fill,
          child: Text(
            emoji.emoji,
            textScaleFactor: 1.0,
            style: TextStyle(
              fontSize: emojiSize,
              backgroundColor: Colors.transparent,
            ),
          ),
        ));
  }

  Widget _buildNoRecent() {
    return Center(
        child: Text(
      widget.config.noRecentsText,
      style: widget.config.noRecentsStyle,
      textAlign: TextAlign.center,
    ));
  }
}
