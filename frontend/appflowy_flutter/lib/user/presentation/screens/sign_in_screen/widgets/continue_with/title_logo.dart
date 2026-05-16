import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/logo/logo.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class TitleLogo extends StatelessWidget {
  const TitleLogo({
    super.key,
    required this.title,
    this.description,
    this.informationBuilder,
  });

  final String title;
  final String? description;
  final WidgetBuilder? informationBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final spacing = VSpace(theme.spacing.xxl);

    return Column(
      children: [
        // logo
        const AFLogo(),
        spacing,

        // title
        Text(
          title,
          style: theme.textStyle.heading3.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        spacing,

        // description
        if (description != null)
          Text(
            description!,
            style: theme.textStyle.body.standard(
              color: theme.textColorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),

        if (informationBuilder != null) informationBuilder!(context),

        spacing,
      ],
    );
  }
}
