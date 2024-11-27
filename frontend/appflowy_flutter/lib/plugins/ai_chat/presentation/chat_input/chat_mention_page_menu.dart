import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_control_cubit.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

const double _itemHeight = 44.0;
const double _noPageHeight = 20.0;
const double _fixedWidth = 360.0;
const double _maxHeight = 600.0;

class ChatInputAnchor {
  ChatInputAnchor(this.anchorKey, this.layerLink);

  final GlobalKey<State<StatefulWidget>> anchorKey;
  final LayerLink layerLink;
}

class ChatMentionPageMenu extends StatefulWidget {
  const ChatMentionPageMenu({
    super.key,
    required this.anchor,
    required this.textController,
    required this.onPageSelected,
  });

  final ChatInputAnchor anchor;
  final TextEditingController textController;
  final void Function(ViewPB view) onPageSelected;

  @override
  State<ChatMentionPageMenu> createState() => _ChatMentionPageMenuState();
}

class _ChatMentionPageMenuState extends State<ChatMentionPageMenu> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<ChatInputControlCubit>().refreshViews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatInputControlCubit, ChatInputControlState>(
      builder: (context, state) {
        return Stack(
          children: [
            CompositedTransformFollower(
              link: widget.anchor.layerLink,
              showWhenUnlinked: false,
              offset: Offset(getPopupOffsetX(), 0.0),
              followerAnchor: Alignment.bottomLeft,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: _fixedWidth,
                  maxWidth: _fixedWidth,
                  maxHeight: _maxHeight,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(6.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A1F2329),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: Color(0x0A1F2329),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x0F1F2329),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: TextFieldTapRegion(
                  child: ChatMentionPageList(
                    onPageSelected: widget.onPageSelected,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double getPopupOffsetX() {
    if (widget.anchor.anchorKey.currentContext == null) {
      return 0.0;
    }

    final cubit = context.read<ChatInputControlCubit>();
    if (cubit.filterStartPosition == -1) {
      return 0.0;
    }

    final textPosition = TextPosition(offset: cubit.filterEndPosition);
    final renderBox =
        widget.anchor.anchorKey.currentContext?.findRenderObject() as RenderBox;

    final textPainter = TextPainter(
      text: TextSpan(text: cubit.formatIntputText(widget.textController.text)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: renderBox.size.width,
      maxWidth: renderBox.size.width,
    );

    final caretOffset = textPainter.getOffsetForCaret(textPosition, Rect.zero);
    final boxes = textPainter.getBoxesForSelection(
      TextSelection(
        baseOffset: textPosition.offset,
        extentOffset: textPosition.offset,
      ),
    );

    if (boxes.isNotEmpty) {
      return boxes.last.right;
    }

    return caretOffset.dx;
  }
}

class ChatMentionPageList extends StatefulWidget {
  const ChatMentionPageList({
    super.key,
    required this.onPageSelected,
  });

  final void Function(ViewPB view) onPageSelected;

  @override
  State<ChatMentionPageList> createState() => _ChatMentionPageListState();
}

class _ChatMentionPageListState extends State<ChatMentionPageList> {
  final autoScrollController = AutoScrollController(
    suggestedRowHeight: _itemHeight,
  );

  @override
  void dispose() {
    autoScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatInputControlCubit, ChatInputControlState>(
      listenWhen: (previous, current) {
        return previous.maybeWhen(
          ready: (pVisibleViews, pFocusedViewIndex) => current.maybeWhen(
            ready: (cIsibleViews, cFocusedViewIndex) =>
                pFocusedViewIndex != cFocusedViewIndex,
            orElse: () => false,
          ),
          orElse: () => false,
        );
      },
      listener: (context, state) {
        state.maybeWhen(
          ready: (views, focusedViewIndex) {
            if (focusedViewIndex == -1 || !autoScrollController.hasClients) {
              return;
            }
            if (autoScrollController.isAutoScrolling) {
              autoScrollController.position
                  .jumpTo(autoScrollController.position.pixels);
            }
            autoScrollController.scrollToIndex(
              focusedViewIndex,
              duration: const Duration(milliseconds: 200),
              preferPosition: AutoScrollPosition.begin,
            );
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.maybeWhen(
          loading: () {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: _noPageHeight,
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            );
          },
          ready: (views, focusedViewIndex) {
            if (views.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: _noPageHeight,
                  child: Center(
                    child: FlowyText(
                      LocaleKeys.chat_inputActionNoPages.tr(),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              cacheExtent: 1,
              addAutomaticKeepAlives: false,
              controller: autoScrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: views.length,
              itemBuilder: (context, index) {
                final view = views[index];
                return AutoScrollTag(
                  key: ValueKey("chat_mention_page_item_${view.id}"),
                  index: index,
                  controller: autoScrollController,
                  child: _ChatMentionPageItem(
                    item: view,
                    onTap: () => widget.onPageSelected(view),
                    isSelected: focusedViewIndex == index,
                  ),
                );
              },
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ChatMentionPageItem extends StatelessWidget {
  const _ChatMentionPageItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ViewPB item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: item.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: _itemHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? AFThemeExtension.of(context).lightGreyHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4.0),
            ),
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                item.defaultIcon(),
                const HSpace(8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlowyText(
                        item.name.isEmpty
                            ? LocaleKeys.document_title_placeholder.tr()
                            : item.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      FlowyText(
                        item.name.isEmpty
                            ? LocaleKeys.document_title_placeholder.tr()
                            : item.name,
                        color: Theme.of(context).hintColor,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
