import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class PageStyleBottomSheet extends StatelessWidget {
  const PageStyleBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // layout: font size, line height and font family.
          FlowyText(LocaleKeys.pageStyle_layout.tr()),
          const VSpace(8.0),
          const PageStyleLayout(),
        ],
      ),
    );
  }
}
