import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:app_flowy/startup/tasks/application_task.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text_input.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class NewAppButton extends StatelessWidget {
  final Function(String)? press;

  const NewAppButton({this.press, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // final theme = context.watch<AppTheme>();

    final child = FlowyTextButton(
      'New App',
      fontSize: 12,
      enableHover: false,
      onPressed: () async => await _showCreateAppDialog(context),
      heading: svgWithSize("home/new_app", const Size(16, 16)),
      padding: EdgeInsets.symmetric(horizontal: Insets.l, vertical: 20),
    );

    return SizedBox(
      height: HomeSizes.menuAddButtonHeight,
      child: child,
    ).topBorder(color: Colors.grey.shade300);
  }

  Future<void> _showCreateAppDialog(BuildContext context) async {
    await CreateAppDialog(
      confirm: (appName) {
        if (appName.isNotEmpty && press != null) {
          press!(appName);
        }
      },
    ).show(context);
  }
}

class CreateAppDialog extends StatefulWidget {
  final void Function()? cancel;
  final void Function(String) confirm;

  const CreateAppDialog({required this.confirm, this.cancel, Key? key}) : super(key: key);

  @override
  State<CreateAppDialog> createState() => _CreateAppDialogState();
}

class _CreateAppDialogState extends State<CreateAppDialog> {
  String appName = "";

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return StyledDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...[
            Text('Create App'.toUpperCase(), style: TextStyles.T1.textColor(theme.shader4)),
            VSpace(Insets.sm * 1.5),
            // Container(color: theme.greyWeak.withOpacity(.35), height: 1),
            VSpace(Insets.m * 1.5),
          ],
          FlowyFormTextInput(
            hintText: "App name",
            onChanged: (text) {
              appName = text;
            },
          ),
          SizedBox(height: Insets.l),
          SizedBox(
            height: 40,
            child: OkCancelButton(
              onOkPressed: () {
                widget.confirm(appName);
              },
              onCancelPressed: () {
                if (widget.cancel != null) {
                  widget.cancel!();
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
