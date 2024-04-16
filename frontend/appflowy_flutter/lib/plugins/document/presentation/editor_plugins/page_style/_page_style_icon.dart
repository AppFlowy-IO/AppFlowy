import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  late final ViewListener viewListener;
  String icon = '';

  @override
  void initState() {
    super.initState();
    icon = widget.view.icon.value;
    viewListener = ViewListener(
      viewId: widget.view.id,
    )..start(
        onViewUpdated: (v) {
          setState(() {
            icon = v.icon.value;
          });
        },
      );
  }

  @override
  void dispose() {
    viewListener.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push<EmojiPickerResult>(
          MobileEmojiPickerScreen.routeName,
        );
        if (result != null && context.mounted) {
          await ViewBackendService.updateViewIcon(
            viewId: widget.view.id,
            viewIcon: result.emoji,
          );
        }
      },
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
  }
}
