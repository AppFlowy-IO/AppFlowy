import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/presentation/widgets/background.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class SkipLogInScreen extends StatelessWidget {
  final IAuthRouter router;
  final IAuth authManager;
  const SkipLogInScreen({Key? key, required this.router, required this.authManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SignInForm(router: router),
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
        width: 400,
        height: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlowyLogoTitle(
              title: 'Welcome to AppFlowy',
              logoSize: Size.square(60),
            ),
            const VSpace(80),
            GoButton(onPressed: _autoRegister),
            const VSpace(30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  child: const Text(
                    'Star on Github',
                    style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                  ),
                  onTap: () {
                    _launchURL('https://github.com/AppFlowy-IO/appflowy');
                  },
                ),
                const Spacer(),
                InkWell(
                  child: const Text(
                    'Subscribe to Newsletter',
                    style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                  ),
                  onTap: () {
                    _launchURL('https://www.appflowy.io/blog');
                  },
                ),
              ],
            )
          ],
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

  void _autoRegister() {}
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
      title: 'Let\'s Go',
      height: 50,
      borderRadius: Corners.s10Border,
      color: theme.main1,
      onPressed: onPressed,
    );
  }
}
