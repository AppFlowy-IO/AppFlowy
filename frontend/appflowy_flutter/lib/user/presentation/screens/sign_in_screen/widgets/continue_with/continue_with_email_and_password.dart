import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_email.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_magic_link_or_passcode.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_password.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';
import 'package:universal_platform/universal_platform.dart';

class ContinueWithEmailAndPassword extends StatefulWidget {
  const ContinueWithEmailAndPassword({super.key});

  @override
  State<ContinueWithEmailAndPassword> createState() =>
      _ContinueWithEmailAndPasswordState();
}

class _ContinueWithEmailAndPasswordState
    extends State<ContinueWithEmailAndPassword> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      children: [
        SizedBox(
          height: UniversalPlatform.isMobile ? 38.0 : 40.0,
          child: AFTextField(
            controller: controller,
            hintText: LocaleKeys.signIn_pleaseInputYourEmail.tr(),
            radius: 10,
            onSubmitted: (value) => _sendMagicLink(
              context,
              value,
            ),
          ),
        ),
        VSpace(theme.spacing.l),
        ContinueWithEmail(
          onTap: () => _sendMagicLink(
            context,
            controller.text,
          ),
        ),
        VSpace(theme.spacing.l),
        ContinueWithPassword(
          onTap: () => _sendMagicLink(
            context,
            controller.text,
          ),
        ),
      ],
    );
  }

  void _sendMagicLink(BuildContext context, String email) {
    if (!isEmail(email)) {
      return showToastNotification(
        context,
        message: LocaleKeys.signIn_invalidEmail.tr(),
        type: ToastificationType.error,
      );
    }

    context.read<SignInBloc>().add(SignInEvent.signedWithMagicLink(email));

    // showConfirmDialog(
    //   context: context,
    //   title: LocaleKeys.signIn_magicLinkSent.tr(),
    //   description: LocaleKeys.signIn_magicLinkSentDescription.tr(),
    // );

    // push the a continue with magic link or passcode screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContinueWithMagicLinkOrPasscode(
          email: email,
          backToLogin: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
