import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class PublishInfoViewItem extends StatelessWidget {
  const PublishInfoViewItem({
    super.key,
    required this.publishInfoView,
    this.onTap,
    this.useIntrinsicWidth = true,
  });

  final PublishInfoViewPB publishInfoView;
  final VoidCallback? onTap;
  final bool useIntrinsicWidth;

  @override
  Widget build(BuildContext context) {
    final name = publishInfoView.view.name;
    return Container(
      alignment: Alignment.centerLeft,
      child: FlowyButton(
        useIntrinsicWidth: useIntrinsicWidth,
        mainAxisAlignment: MainAxisAlignment.start,
        leftIcon: _buildIcon(),
        text: FlowyText.regular(
          name.orDefault(
            LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
          ),
          fontSize: 14.0,
          figmaLineHeight: 18.0,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildIcon() {
    final icon = publishInfoView.view.icon.value;
    return icon.isNotEmpty
        ? FlowyText.emoji(
            icon,
            fontSize: 16.0,
            figmaLineHeight: 18.0,
          )
        : publishInfoView.view.defaultIcon();
  }
}
