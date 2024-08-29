import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';
import 'package:toastification/toastification.dart';

class SignInWithMagicLinkButtons extends StatefulWidget {
  const SignInWithMagicLinkButtons({super.key});

  @override
  State<SignInWithMagicLinkButtons> createState() =>
      _SignInWithMagicLinkButtonsState();
}

class _SignInWithMagicLinkButtonsState
    extends State<SignInWithMagicLinkButtons> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: PlatformExtension.isMobile ? 38.0 : 48.0,
          child: FlowyTextField(
            autoFocus: false,
            controller: controller,
            borderRadius: BorderRadius.circular(4.0),
            hintText: LocaleKeys.signIn_pleaseInputYourEmail.tr(),
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14.0,
                  color: Theme.of(context).hintColor,
                ),
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14.0,
                ),
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _sendMagicLink(context, controller.text),
          ),
        ),
        const VSpace(12),
        _ConfirmButton(
          onTap: () => _sendMagicLink(context, controller.text),
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

    showConfirmDialog(
      context: context,
      title: LocaleKeys.signIn_magicLinkSent.tr(),
      description: LocaleKeys.signIn_magicLinkSentDescription.tr(),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) {
        final name = switch (state.loginType) {
          LoginType.signIn => LocaleKeys.signIn_signInWithMagicLink.tr(),
          LoginType.signUp => LocaleKeys.signIn_signUpWithMagicLink.tr(),
        };
        if (PlatformExtension.isMobile) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 32),
              maximumSize: const Size(double.infinity, 38),
            ),
            onPressed: onTap,
            child: FlowyText(
              name,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          );
        } else {
          return SizedBox(
            height: 48,
            child: FlowyButton(
              isSelected: true,
              onTap: onTap,
              hoverColor: Theme.of(context).colorScheme.primary,
              text: FlowyText.medium(
                name,
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              radius: Corners.s6Border,
            ),
          );
        }
      },
    );
  }
}
