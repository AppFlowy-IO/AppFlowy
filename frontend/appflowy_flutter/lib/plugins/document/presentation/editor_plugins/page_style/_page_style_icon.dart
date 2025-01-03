import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_icon_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';

class PageStyleIcon extends StatefulWidget {
  const PageStyleIcon({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  State<PageStyleIcon> createState() => _PageStyleIconState();
}

class _PageStyleIconState extends State<PageStyleIcon> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageStyleIconBloc(view: widget.view)
        ..add(const PageStyleIconEvent.initial()),
      child: BlocBuilder<PageStyleIconBloc, PageStyleIconState>(
        builder: (context, state) {
          final icon = state.icon ?? EmojiIconData.none();
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
                  icon.isEmpty
                      ? FlowyText(
                          LocaleKeys.pageStyle_none.tr(),
                          fontSize: 16.0,
                        )
                      : RawEmojiIconWidget(
                          emoji: icon,
                          emojiSize: 22.0,
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

  void _showIconSelector(BuildContext context, EmojiIconData icon) {
    Navigator.pop(context);
    final pageStyleIconBloc = PageStyleIconBloc(view: widget.view)
      ..add(const PageStyleIconEvent.initial());
    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      showHeader: true,
      title: LocaleKeys.titleBar_pageIcon.tr(),
      backgroundColor: AFThemeExtension.of(context).background,
      enableDraggableScrollable: true,
      minChildSize: 0.6,
      initialChildSize: 0.61,
      scrollableWidgetBuilder: (ctx, controller) {
        return BlocProvider.value(
          value: pageStyleIconBloc,
          child: Expanded(
            child: FlowyIconEmojiPicker(
              initialType: icon.type.toPickerTabType(),
              onSelectedEmoji: (r) {
                pageStyleIconBloc.add(
                  PageStyleIconEvent.updateIcon(r.data, true),
                );
                if (!r.keepOpen) Navigator.pop(ctx);
              },
            ),
          ),
        );
      },
      builder: (_) => const SizedBox.shrink(),
    );
  }
}
