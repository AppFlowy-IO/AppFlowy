import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_icon_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';

class PageStyleIcon extends StatelessWidget {
  const PageStyleIcon({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageStyleIconBloc(view: view)
        ..add(const PageStyleIconEvent.initial()),
      child: BlocBuilder<PageStyleIconBloc, PageStyleIconState>(
        builder: (context, state) {
          final icon = state.icon ?? '';
          return GestureDetector(
            onTap: () => _showIconSelector(context, icon),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: context.pageStyleBackgroundColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  const HSpace(16.0),
                  FlowyText(LocaleKeys.document_plugins_emoji.tr()),
                  const Spacer(),
                  FlowyText(
                    icon.isNotEmpty ? icon : LocaleKeys.pageStyle_none.tr(),
                    color: icon.isEmpty ? context.pageStyleTextColor : null,
                    fontSize: icon.isNotEmpty ? 22.0 : 16.0,
                  ),
                  const HSpace(6.0),
                  const FlowySvg(FlowySvgs.m_page_style_arrow_right_s),
                  const HSpace(12.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showIconSelector(BuildContext context, String selectedIcon) {
    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      showDoneButton: true,
      showHeader: true,
      title: LocaleKeys.titleBar_pageIcon.tr(),
      barrierColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.background,
      isScrollControlled: true,
      enableDraggableScrollable: true,
      minChildSize: 0.6,
      initialChildSize: 0.61,
      showRemoveButton: true,
      onRemove: () {
        context.read<PageStyleIconBloc>().add(
              const PageStyleIconEvent.updateIcon('', true),
            );
      },
      scrollableWidgetBuilder: (_, controller) {
        return BlocProvider.value(
          value: context.read<PageStyleIconBloc>(),
          child: Expanded(
            child: _IconSelector(
              scrollController: controller,
            ),
          ),
        );
      },
      builder: (_) => const SizedBox.shrink(),
    );
  }
}

class _IconSelector extends StatefulWidget {
  const _IconSelector({
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<_IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<_IconSelector> {
  EmojiData? emojiData;
  List<String> availableEmojis = [];

  @override
  void initState() {
    super.initState();

    // load the emoji data from cache if it's available
    if (kCachedEmojiData != null) {
      emojiData = kCachedEmojiData;
      availableEmojis = _setupAvailableEmojis(emojiData!);
    } else {
      EmojiData.builtIn().then(
        (value) {
          kCachedEmojiData = value;
          setState(() {
            emojiData = value;
            availableEmojis = _setupAvailableEmojis(value);
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (availableEmojis.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RepaintBoundary(
      child: BlocBuilder<PageStyleIconBloc, PageStyleIconState>(
        builder: (_, state) => GridView.count(
          crossAxisCount: _getEmojiPerLine(context),
          controller: widget.scrollController,
          children: [
            for (final emoji in availableEmojis)
              _buildEmoji(context, emoji, state.icon),
          ],
        ),
      ),
    );
  }

  Widget _buildEmoji(
    BuildContext context,
    String emoji,
    String? selectedEmoji,
  ) {
    Widget child = Center(
      child: FlowyText.emoji(
        emoji,
        fontSize: 24,
      ),
    );

    if (emoji == selectedEmoji) {
      child = Container(
        margin: const EdgeInsets.all(8.0),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1.50,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: Color(0xFF00BCF0),
            ),
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: child,
      );
    }

    return GestureDetector(
      onTap: () {
        context.read<PageStyleIconBloc>().add(
              PageStyleIconEvent.updateIcon(emoji, true),
            );
      },
      child: child,
    );
  }

  List<String> _setupAvailableEmojis(EmojiData emojiData) {
    final categories = emojiData.categories;
    availableEmojis = categories
        .map((e) => e.emojiIds.map((e) => emojiData.getEmojiById(e)))
        .expand((e) => e)
        .toList();
    return availableEmojis;
  }

  int _getEmojiPerLine(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width ~/ 48.0; // the size of the emoji
  }

  // Widget _buildSearchBar(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(
  //       vertical: 8.0,
  //       horizontal: 12.0,
  //     ),
  //     child: FlowyMobileSearchTextField(
  //       onChanged: (keyword) {
  //         setState(() {
  //           availableFonts = _availableFonts
  //               .where(
  //                 (font) =>
  //                     font.isEmpty || // keep the default one always
  //                     font
  //                         .parseFontFamilyName()
  //                         .toLowerCase()
  //                         .contains(keyword.toLowerCase()),
  //               )
  //               .toList();
  //         });
  //       },
  //     ),
  //   );
  // }
}
