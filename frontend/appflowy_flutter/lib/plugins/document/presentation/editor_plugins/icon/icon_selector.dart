import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_search_text_field.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_icon_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';

class IconSelector extends StatefulWidget {
  const IconSelector({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> {
  EmojiData? emojiData;
  List<String> availableEmojis = [];

  PageStyleIconBloc? pageStyleIconBloc;

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

    pageStyleIconBloc = context.read<PageStyleIconBloc>();
  }

  @override
  void dispose() {
    pageStyleIconBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (emojiData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RepaintBoundary(
      child: BlocBuilder<PageStyleIconBloc, PageStyleIconState>(
        builder: (_, state) => Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                controller: widget.scrollController,
                children: [
                  for (final emoji in availableEmojis)
                    _buildEmoji(context, emoji, state.icon),
                ],
              ),
            ),
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
    Widget child = SizedBox.square(
      dimension: 24.0,
      child: Center(
        child: FlowyText.emoji(
          emoji,
          fontSize: 24,
        ),
      ),
    );

    if (emoji == selectedEmoji) {
      child = Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1.40,
                strokeAlign: BorderSide.strokeAlignOutside,
                color: Color(0xFF00BCF0),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: child,
        ),
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 12.0,
      ),
      child: FlowyMobileSearchTextField(
        onChanged: (keyword) {
          if (emojiData == null) {
            return;
          }

          final filtered = emojiData!.filterByKeyword(keyword);
          final availableEmojis = _setupAvailableEmojis(filtered);

          setState(() {
            this.availableEmojis = availableEmojis;
          });
        },
      ),
    );
  }
}
