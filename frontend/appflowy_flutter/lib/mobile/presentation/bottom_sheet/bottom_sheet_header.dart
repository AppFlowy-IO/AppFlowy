import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class BottomSheetHeader extends StatelessWidget {
  const BottomSheetHeader({
    super.key,
    this.title,
    this.onClose,
    this.onDone,
  });

  final String? title;
  final VoidCallback? onClose;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (onClose != null)
          Positioned(
            left: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppBarCloseButton(
                margin: EdgeInsets.zero,
                onTap: onClose,
              ),
            ),
          ),
        if (title != null)
          Align(
            alignment: Alignment.center,
            child: FlowyText.medium(
              title!,
              fontSize: 16,
            ),
          ),
        if (onDone != null)
          Align(
            alignment: Alignment.centerRight,
            child: FlowyButton(
              useIntrinsicWidth: true,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Color(0xFF00BCF0),
              ),
              text: FlowyText.medium(
                LocaleKeys.button_Done.tr(),
                color: Colors.white,
                fontSize: 16.0,
              ),
              onTap: onDone,
            ),
          ),
      ],
    );
  }
}
