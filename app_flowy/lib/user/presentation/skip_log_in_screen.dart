// ignore_for_file: prefer_const_constructors

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/sign_in_bloc.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/presentation/widgets/background.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';

class SkipLogInScreen extends StatelessWidget {
  final IAuthRouter router;
  const SkipLogInScreen({Key? key, required this.router}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocListener<SignInBloc, SignInState>(
        listener: (context, state) {
          state.successOrFail.fold(
            () => null,
            (result) => _handleSuccessOrFail(result, context),
          );
        },
        child: Scaffold(
          body: SignInForm(router: router),
        ),
      ),
    );
  }

  void _handleSuccessOrFail(Either<UserProfile, UserError> result, BuildContext context) {
    result.fold(
      (user) => router.pushWelcomeScreen(context, user),
      (error) => showSnapBar(context, error.msg),
    );
  }
}

class SignInForm extends StatelessWidget {
  final IAuthRouter router;
  const SignInForm({
    Key? key,
    required this.router,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 600,
        height: 600,
        child: Expanded(
          child: Column(
            // ignore: prefer_const_literals_to_create_immutables
            children: [
              const AuthFormTitle(
                title: 'Welcome to AppFlowy',
                logoSize: Size(60, 60),
              ),
              const VSpace(80),
              const GoButton(),
              const VSpace(30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ignore: prefer_const_constructors
                  InkWell(
                    child: Text(
                      'Star on Github',
                      style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                    ),
                    onTap: () {
                      _launchURL('https://github.com/AppFlowy-IO/appflowy');
                    },
                  ),
                  HSpace(60),
                  InkWell(
                      child: Text(
                        'Subscribe to Newsletter',
                        style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                      ),
                      onTap: () {
                        _launchURL('https://www.appflowy.io/blog');
                      }),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class GoButton extends StatelessWidget {
  const GoButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return RoundedTextButton(
      title: 'Let\'s Go',
      height: 60,
      borderRadius: Corners.s10Border,
      color: theme.main1,
      onPressed: () {
        //to do: direct to the workspace
      },
    );
  }
}
