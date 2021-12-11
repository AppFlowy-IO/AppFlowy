import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/presentation/widgets/background.dart';
import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:app_flowy/generated/locale_keys.g.dart';

class SkipLogInScreen extends StatefulWidget {
  final IAuthRouter router;
  final IAuth authManager;

  const SkipLogInScreen({
    Key? key,
    required this.router,
    required this.authManager,
  }) : super(key: key);

  @override
  State<SkipLogInScreen> createState() => _SkipLogInScreenState();
}

class _SkipLogInScreenState extends State<SkipLogInScreen> {
  IUserListener? userListener;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 600,
          child: _renderBody(context),
        ),
      ),
    );
  }

  Widget _renderBody(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlowyLogoTitle(
          title: LocaleKeys.welcomeText.tr(),
          logoSize: const Size.square(60),
        ),
        const VSpace(80),
        GoButton(onPressed: () => _autoRegister(context)),
        const VSpace(30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              child: Text(
                LocaleKeys.githubStarText.tr(),
                style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
              ),
              onTap: () {
                _launchURL('https://github.com/AppFlowy-IO/appflowy');
              },
            ),
            InkWell(
              child: Text(
                LocaleKeys.subscribeNewsletterText.tr(),
                style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
              ),
              onTap: () {
                _launchURL('https://www.appflowy.io/blog');
              },
            ),
          ],
        )
      ],
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _autoRegister(BuildContext context) async {
    const password = "AppFlowy123@";
    final uid = uuid();
    final userEmail = "$uid@appflowy.io";
    final result = await widget.authManager.signUp(LocaleKeys.defaultUsername.tr(), password, userEmail);
    result.fold(
      (user) {
        WorkspaceEventReadCurWorkspace().send().then((result) {
          _openCurrentWorkspace(context, user, result);
        });
      },
      (error) {
        Log.error(error);
      },
    );
  }

  void _openCurrentWorkspace(
    BuildContext context,
    UserProfile user,
    dartz.Either<CurrentWorkspaceSetting, WorkspaceError> workspacesOrError,
  ) {
    workspacesOrError.fold(
      (workspaceSetting) {
        widget.router.pushHomeScreen(context, user, workspaceSetting);
      },
      (error) {
        Log.error(error);
      },
    );
  }
}

class GoButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return RoundedTextButton(
      title: LocaleKeys.letsGoButtonText.tr(),
      height: 50,
      borderRadius: Corners.s10Border,
      color: theme.main1,
      onPressed: onPressed,
    );
  }
}
