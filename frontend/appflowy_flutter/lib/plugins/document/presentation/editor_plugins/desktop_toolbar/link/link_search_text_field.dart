import 'dart:math';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/list_extension.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/recent/cached_recent_service.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/flutter/scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'link_create_menu.dart';
import 'link_styles.dart';

class LinkSearchTextField {
  LinkSearchTextField({
    this.onEscape,
    this.onEnter,
    this.onDataRefresh,
    this.initialViewId = '',
    required this.currentViewId,
    String? initialSearchText,
  }) : textEditingController = TextEditingController(
          text: initialSearchText ?? '',
        );

  final TextEditingController textEditingController;
  final String initialViewId;
  final String currentViewId;
  final ItemScrollController searchController = ItemScrollController();
  late FocusNode focusNode = FocusNode(onKeyEvent: onKeyEvent);
  final List<ViewPB> searchedViews = [];
  final List<ViewPB> recentViews = [];
  int selectedIndex = 0;

  final VoidCallback? onEscape;
  final VoidCallback? onEnter;
  final VoidCallback? onDataRefresh;

  String get searchText => textEditingController.text;

  bool get isButtonEnable => searchText.isNotEmpty && isUrl;

  bool get showingRecent => searchText.isEmpty && recentViews.isNotEmpty;

  ViewPB get currentSearchedView => searchedViews[selectedIndex];

  ViewPB get currentRecentView => recentViews[selectedIndex];

  bool get isUrl {
    return hrefRegex.hasMatch(searchText) ||
        searchText.startsWith('mailto:') ||
        searchText.startsWith('file:');
  }

  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    searchedViews.clear();
    recentViews.clear();
  }

  Widget buildTextField({bool autofocus = false}) {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofocus: autofocus,
      focusNode: focusNode,
      textAlign: TextAlign.left,
      controller: textEditingController,
      style: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      ),
      onChanged: (text) {
        if (text.isEmpty) {
          searchedViews.clear();
          selectedIndex = 0;
          onDataRefresh?.call();
        } else {
          searchViews(text);
        }
      },
      decoration: LinkStyle.buildLinkTextFieldInputDecoration(
        LocaleKeys.document_toolbar_linkInputHint.tr(),
        showErrorBorder: !isButtonEnable,
      ),
    );
  }

  Widget buildResultContainer({
    EdgeInsetsGeometry? margin,
    required BuildContext context,
    VoidCallback? onLinkSelected,
    ValueChanged<ViewPB>? onPageLinkSelected,
    double width = 320.0,
  }) {
    return onSearchResult<Widget>(
      onEmpty: () => SizedBox.shrink(),
      onLink: () => Container(
        height: 48,
        width: width,
        padding: EdgeInsets.all(8),
        margin: margin,
        decoration: buildToolbarLinkDecoration(context),
        child: FlowyButton(
          leftIcon: FlowySvg(FlowySvgs.toolbar_link_earth_m),
          isSelected: true,
          text: FlowyText.regular(
            searchText,
            overflow: TextOverflow.ellipsis,
            fontSize: 14,
            figmaLineHeight: 20,
          ),
          onTap: onLinkSelected,
        ),
      ),
      onRecentViews: () => Container(
        width: width,
        height: recentViews.length.clamp(1, 5) * 32.0 + 48,
        margin: margin,
        padding: EdgeInsets.all(8),
        decoration: buildToolbarLinkDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 32,
              padding: EdgeInsets.all(8),
              child: FlowyText.semibold(
                LocaleKeys.inlineActions_recentPages.tr(),
                color: LinkStyle.textTertiary,
                fontSize: 12,
                figmaLineHeight: 16,
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  final currentView = recentViews[index];
                  return buildPageItem(
                    currentView,
                    index == selectedIndex,
                    onPageLinkSelected,
                  );
                },
                itemCount: recentViews.length,
              ),
            ),
          ],
        ),
      ),
      onSearchViews: () => Container(
        width: width,
        height: searchedViews.length.clamp(1, 5) * 32.0 + 16,
        margin: margin,
        decoration: buildToolbarLinkDecoration(context),
        child: ScrollablePositionedList.builder(
          padding: EdgeInsets.all(8),
          physics: const ClampingScrollPhysics(),
          shrinkWrap: true,
          itemCount: searchedViews.length,
          itemScrollController: searchController,
          initialScrollIndex: max(0, selectedIndex),
          itemBuilder: (context, index) {
            final currentView = searchedViews[index];
            return buildPageItem(
              currentView,
              index == selectedIndex,
              onPageLinkSelected,
            );
          },
        ),
      ),
    );
  }

  Widget buildPageItem(
    ViewPB view,
    bool isSelected,
    ValueChanged<ViewPB>? onSubmittedPageLink,
  ) {
    final viewName = view.name;
    final displayName = viewName.isEmpty
        ? LocaleKeys.document_title_placeholder.tr()
        : viewName;
    final isCurrent = initialViewId == view.id;
    return SizedBox(
      height: 32,
      child: FlowyButton(
        isSelected: isSelected,
        leftIcon: buildIcon(view, padding: EdgeInsets.zero),
        text: FlowyText.regular(
          displayName,
          overflow: TextOverflow.ellipsis,
          fontSize: 14,
          figmaLineHeight: 20,
        ),
        rightIcon: isCurrent ? FlowySvg(FlowySvgs.toolbar_check_m) : null,
        onTap: () => onSubmittedPageLink?.call(view),
      ),
    );
  }

  Widget buildIcon(
    ViewPB view, {
    EdgeInsetsGeometry padding = const EdgeInsets.only(top: 4),
  }) {
    if (view.icon.value.isEmpty) return view.defaultIcon(size: Size(20, 20));
    final iconData = view.icon.toEmojiIconData();
    return Padding(
      padding: padding,
      child: RawEmojiIconWidget(
        emoji: iconData,
        emojiSize: iconData.type == FlowyIconType.emoji ? 16 : 20,
        lineHeight: 1,
      ),
    );
  }

  void requestFocus() => focusNode.requestFocus();

  void unfocus() => focusNode.unfocus();

  void updateText(String text) => textEditingController.text = text;

  T onSearchResult<T>({
    required ValueGetter<T> onLink,
    required ValueGetter<T> onRecentViews,
    required ValueGetter<T> onSearchViews,
    required ValueGetter<T> onEmpty,
  }) {
    if (searchedViews.isEmpty && recentViews.isEmpty && searchText.isEmpty) {
      return onEmpty.call();
    }
    if (searchedViews.isEmpty && searchText.isNotEmpty) {
      return onLink.call();
    }
    if (searchedViews.isEmpty) return onRecentViews.call();
    return onSearchViews.call();
  }

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent key) {
    if (key is! KeyDownEvent) return KeyEventResult.ignored;
    int index = selectedIndex;
    if (key.logicalKey == LogicalKeyboardKey.escape) {
      onEscape?.call();
      return KeyEventResult.handled;
    } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
      index = onSearchResult(
        onLink: () => 0,
        onRecentViews: () {
          int result = index - 1;
          if (result < 0) result = recentViews.length - 1;
          return result;
        },
        onSearchViews: () {
          int result = index - 1;
          if (result < 0) result = searchedViews.length - 1;
          searchController.scrollTo(
            index: result,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
          );
          return result;
        },
        onEmpty: () => 0,
      );
      refreshIndex(index);
      return KeyEventResult.handled;
    } else if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
      index = onSearchResult(
        onLink: () => 0,
        onRecentViews: () {
          int result = index + 1;
          if (result >= recentViews.length) result = 0;
          return result;
        },
        onSearchViews: () {
          int result = index + 1;
          if (result >= searchedViews.length) result = 0;
          searchController.scrollTo(
            index: result,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
          );
          return result;
        },
        onEmpty: () => 0,
      );
      refreshIndex(index);
      return KeyEventResult.handled;
    } else if (key.logicalKey == LogicalKeyboardKey.enter) {
      onEnter?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> searchRecentViews() async {
    final recentService = getIt<CachedRecentService>();
    final sectionViews = await recentService.recentViews();
    final views = sectionViews
        .unique((e) => e.item.id)
        .map((e) => e.item)
        .where((e) => e.id != currentViewId)
        .take(5)
        .toList();
    recentViews.clear();
    recentViews.addAll(views);
    selectedIndex = 0;
    onDataRefresh?.call();
  }

  Future<void> searchViews(String search) async {
    final viewResult = await ViewBackendService.getAllViews();
    final allViews = viewResult
        .toNullable()
        ?.items
        .where(
          (view) =>
              (view.id != currentViewId) &&
              (view.name.toLowerCase().contains(search.toLowerCase()) ||
                  (view.name.isEmpty && search.isEmpty) ||
                  (view.name.isEmpty &&
                      LocaleKeys.menuAppHeader_defaultNewPageName
                          .tr()
                          .toLowerCase()
                          .contains(search.toLowerCase()))),
        )
        .take(10)
        .toList();
    searchedViews.clear();
    searchedViews.addAll(allViews ?? []);
    selectedIndex = 0;
    onDataRefresh?.call();
  }

  void refreshIndex(int index) {
    selectedIndex = index;
    onDataRefresh?.call();
  }
}
