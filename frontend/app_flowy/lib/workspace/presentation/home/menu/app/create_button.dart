import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class NewAppButton extends StatelessWidget {
  final Function(String)? press;

  const NewAppButton({this.press, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final child = FlowyTextButton(
      LocaleKeys.newPageText.tr(),
      fillColor: Colors.transparent,
      hoverColor: Colors.transparent,
      fontColor: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: () async => await _showCreateAppDialog(context),
      heading: svgWidget("home/new_app", size: const Size(16, 16)),
      padding: EdgeInsets.symmetric(horizontal: Insets.l, vertical: 20),
    );

    return SizedBox(
      height: HomeSizes.menuAddButtonHeight,
      child: child,
    ).topBorder(color: Theme.of(context).dividerColor);
  }

  Future<void> _showCreateAppDialog(BuildContext context) async {
    return NavigatorTextFieldDialog(
      title: LocaleKeys.newPageText.tr(),
      value: "",
      confirm: (newValue) {
        if (newValue.isNotEmpty && press != null) {
          press!(newValue);
        }
      },
    ).show(context);
  }
}
