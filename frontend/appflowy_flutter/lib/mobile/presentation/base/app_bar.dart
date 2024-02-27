import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum FlowyAppBarLeadingType {
  back,
  close,
  cancel;

  Widget getWidget(VoidCallback? onTap) {
    switch (this) {
      case FlowyAppBarLeadingType.back:
        return AppBarBackButton(onTap: onTap);
      case FlowyAppBarLeadingType.close:
        return AppBarCloseButton(onTap: onTap);
      case FlowyAppBarLeadingType.cancel:
        return AppBarCancelButton(onTap: onTap);
    }
  }

  double? get width {
    switch (this) {
      case FlowyAppBarLeadingType.back:
        return 40.0;
      case FlowyAppBarLeadingType.close:
        return 40.0;
      case FlowyAppBarLeadingType.cancel:
        return 120;
    }
  }
}

class FlowyAppBar extends AppBar {
  FlowyAppBar({
    super.key,
    super.actions,
    Widget? title,
    String? titleText,
    FlowyAppBarLeadingType leadingType = FlowyAppBarLeadingType.back,
    super.centerTitle,
    VoidCallback? onTapLeading,
    bool showDivider = true,
  }) : super(
          title: title ??
              FlowyText(
                titleText ?? '',
                fontSize: 15.0,
                fontWeight: FontWeight.w500,
              ),
          titleSpacing: 0,
          elevation: 0,
          leading: leadingType.getWidget(onTapLeading),
          leadingWidth: leadingType.width,
          toolbarHeight: 44.0,
          bottom: showDivider
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(0.5),
                  child: Divider(
                    height: 0.5,
                  ),
                )
              : null,
        );
}
