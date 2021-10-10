import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/create_dialog.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';

class NewAppButton extends StatelessWidget {
  final Function(String)? press;

  const NewAppButton({this.press, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // final theme = context.watch<AppTheme>();
    return SizedBox(
      height: HomeSizes.menuAddButtonHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          svgWithSize("home/new_app", const Size(16, 16)),
          TextButton(
            onPressed: () async => await _showCreateAppDialog(context),
            child: const FlowyText(
              'New App',
              fontSize: 12,
            ),
          )
        ],
      ).padding(horizontal: Insets.l),
    ).topBorder(color: Colors.grey.shade300);
  }

  Future<void> _showCreateAppDialog(BuildContext context) async {
    await Dialogs.showWithContext(CreateAppDialogContext(
      confirm: (appName) {
        if (appName.isNotEmpty && press != null) {
          press!(appName);
        }
      },
    ), context);
  }
}
