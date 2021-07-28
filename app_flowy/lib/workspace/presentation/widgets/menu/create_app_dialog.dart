import 'package:app_flowy/startup/tasks/application_task.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text_input.dart';
import 'package:flowy_infra_ui/widget/buttons/ok_cancel_button.dart';
import 'package:flowy_infra_ui/widget/dialog/dialog_context.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

// ignore: must_be_immutable
class CreateAppDialogContext extends DialogContext {
  String appName;
  final Function(String)? confirm;

  CreateAppDialogContext({this.appName = "", this.confirm})
      : super(identifier: 'CreateAppDialogContext');

  @override
  Widget buildWiget(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return StyledDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...[
            Text('Create App'.toUpperCase(),
                style: TextStyles.T1.textColor(theme.bg1)),
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
          OkCancelButton(
            onOkPressed: () {
              if (confirm != null) {
                confirm!(appName);
                AppGlobals.nav.pop();
              }
            },
            onCancelPressed: () {
              AppGlobals.nav.pop();
            },
          )
        ],
      ),
    );
  }

  @override
  List<Object> get props => [identifier];

  @override
  bool get barrierDismissable => false;
}
