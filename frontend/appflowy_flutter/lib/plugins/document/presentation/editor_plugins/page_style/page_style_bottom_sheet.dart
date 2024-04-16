import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_cover_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_icon.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_layout.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class PageStyleBottomSheet extends StatelessWidget {
  const PageStyleBottomSheet({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // cover image
          FlowyText(
            LocaleKeys.pageStyle_backgroundImage.tr(),
            color: context.pageStyleTextColor,
            fontSize: 14.0,
          ),
          const VSpace(8.0),
          PageStyleCoverImage(),
          const VSpace(20.0),
          // layout: font size, line height and font family.
          FlowyText(
            LocaleKeys.pageStyle_layout.tr(),
            color: context.pageStyleTextColor,
            fontSize: 14.0,
          ),
          const VSpace(8.0),
          const PageStyleLayout(),
          const VSpace(20.0),
          // icon
          FlowyText(
            LocaleKeys.document_plugins_emoji.tr(),
            color: context.pageStyleTextColor,
            fontSize: 14.0,
          ),
          const VSpace(8.0),
          PageStyleIcon(
            view: view,
          ),
        ],
      ),
    );
  }
}
