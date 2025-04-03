import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/logo/logo.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FlowyLogoTitle extends StatelessWidget {
  const FlowyLogoTitle({
    super.key,
    required this.title,
    this.logoSize = const Size.square(40),
  });

  final String title;
  final Size logoSize;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AFLogo(size: logoSize),
          const VSpace(20),
          Text(
            title,
            style: theme.textStyle.heading.h3(
              color: theme.textColorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
