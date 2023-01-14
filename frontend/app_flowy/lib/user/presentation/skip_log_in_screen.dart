import 'package:dartz/dartz.dart' as dartz;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/locale_keys.g.dart';
import '../../main.dart';
import '../../startup/launch_configuration.dart';
import '../../startup/startup.dart';
import '../application/auth_service.dart';
import 'folder/folder_widget.dart';
import 'router.dart';
import 'widgets/background.dart';

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
        child: _renderBody(context),
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
        const VSpace(40),
        SizedBox(
          width: 250,
          child: GoButton(onPressed: () => _autoRegister(context)),
        ),
        const VSpace(20),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: FolderWidget(
            createFolderCallback: () async {
              await FlowyRunner.run(
                FlowyApp(),
                config: const LaunchConfiguration(
                  autoRegistrationSupported: true,
                ),
              );
            },
          ),
        ),
        const VSpace(20),
        SizedBox(
          width: 400,
          child: _buildSubscribeButtons(context),
        ),
      ],
    );
  }

  Row _buildSubscribeButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FlowyTextButton(
          LocaleKeys.githubStarText.tr(),
          fontWeight: FontWeight.w500,
          fontColor: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          hoverColor: Colors.transparent,
          fillColor: Colors.transparent,
          onPressed: () =>
              _launchURL('https://github.com/AppFlowy-IO/appflowy'),
        ),
        FlowyTextButton(
          LocaleKeys.subscribeNewsletterText.tr(),
          fontWeight: FontWeight.w500,
          fontColor: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          hoverColor: Colors.transparent,
          fillColor: Colors.transparent,
          onPressed: () => _launchURL('https://www.appflowy.io/blog'),
        ),
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

  Future<void> _autoRegister(BuildContext context) async {
    final result = await widget.authService.signUpWithRandomUser();
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
      fontSize: FontSizes.s16,
      height: 50,
      borderRadius: Corners.s10Border,
      onPressed: onPressed,
    );
  }
}
