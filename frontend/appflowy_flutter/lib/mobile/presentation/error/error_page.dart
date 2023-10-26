import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileErrorPage extends StatelessWidget {
  const MobileErrorPage({
    super.key,
    this.header,
    this.title,
    required this.message,
  });

  final Widget? header;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        header != null
            ? header!
            : const FlowyText.semibold(
                '😔',
                fontSize: 50,
              ),
        const VSpace(14.0),
        FlowyText.semibold(
          title ?? LocaleKeys.error_weAreSorry.tr(),
          fontSize: 32,
          textAlign: TextAlign.center,
        ),
        const VSpace(4.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: FlowyText.regular(
            message,
            fontSize: 16,
            maxLines: 100,
            color: Colors.grey, // FIXME: use theme color
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
