import 'package:app_flowy/user/application/auth_service.dart';
import 'package:app_flowy/user/presentation/router.dart';
import 'package:app_flowy/user/presentation/widgets/background.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:app_flowy/generated/locale_keys.g.dart';

class SkipLogInScreen extends StatefulWidget {
  final AuthRouter router;
  final AuthService authService;

  const SkipLogInScreen({
    Key? key,
    required this.router,
    required this.authService,
  }) : super(key: key);

  @override
  State<SkipLogInScreen> createState() => _SkipLogInScreenState();
}

class _SkipLogInScreenState extends State<SkipLogInScreen> {
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
              hoverColor: Colors.transparent,
              onTap: () =>
                  _launchURL('https://github.com/AppFlowy-IO/appflowy'),
              child: FlowyText.medium(
                LocaleKeys.githubStarText.tr(),
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            InkWell(
              hoverColor: Colors.transparent,
              onTap: () => _launchURL('https://www.appflowy.io/blog'),
              child: FlowyText.medium(
                LocaleKeys.subscribeNewsletterText.tr(),
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        )
      ],
    );
  }

  _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _autoRegister(BuildContext context) async {
    const password = "AppFlowy123@";
    final uid = uuid();
    final userEmail = "$uid@appflowy.io";
    final result = await widget.authService.signUp(
      name: LocaleKeys.defaultUsername.tr(),
      password: password,
      email: userEmail,
    );
    result.fold(
      (user) {
        FolderEventReadCurrentWorkspace().send().then((result) {
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
    UserProfilePB user,
    dartz.Either<WorkspaceSettingPB, FlowyError> workspacesOrError,
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
    return RoundedTextButton(
      title: LocaleKeys.letsGoButtonText.tr(),
      height: 50,
      borderRadius: Corners.s10Border,
      color: Theme.of(context).colorScheme.primary,
      onPressed: onPressed,
    );
  }
}
