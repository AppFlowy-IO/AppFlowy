import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/anon_user_bloc.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

/// Used in DesktopSignInScreen and MobileSignInScreen
class SignInAnonymousButton extends StatelessWidget {
  const SignInAnonymousButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = UniversalPlatform.isMobile;

    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, signInState) {
        return BlocProvider(
          create: (context) => AnonUserBloc()
            ..add(
              const AnonUserEvent.initial(),
            ),
          child: BlocListener<AnonUserBloc, AnonUserState>(
            listener: (context, state) async {
              if (state.openedAnonUser != null) {
                await runAppFlowy();
              }
            },
            child: BlocBuilder<AnonUserBloc, AnonUserState>(
              builder: (context, state) {
                final text = state.anonUsers.isEmpty
                    ? LocaleKeys.signIn_loginStartWithAnonymous.tr()
                    : LocaleKeys.signIn_continueAnonymousUser.tr();
                final onTap = state.anonUsers.isEmpty
                    ? () {
                        context
                            .read<SignInBloc>()
                            .add(const SignInEvent.signedInAsGuest());
                      }
                    : () {
                        final bloc = context.read<AnonUserBloc>();
                        final user = bloc.state.anonUsers.first;
                        bloc.add(AnonUserEvent.openAnonUser(user));
                      };
                // SignInAnonymousButton in mobile
                if (isMobile) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    onPressed: onTap,
                    child: FlowyText(
                      LocaleKeys.signIn_loginStartWithAnonymous.tr(),
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                // SignInAnonymousButton in desktop
                return SizedBox(
                  height: 48,
                  child: FlowyButton(
                    isSelected: true,
                    disable: signInState.isSubmitting,
                    text: FlowyText.medium(
                      text,
                      textAlign: TextAlign.center,
                    ),
                    radius: Corners.s6Border,
                    onTap: onTap,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class SignInAnonymousButtonV2 extends StatelessWidget {
  const SignInAnonymousButtonV2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, signInState) {
        return BlocProvider(
          create: (context) => AnonUserBloc()
            ..add(
              const AnonUserEvent.initial(),
            ),
          child: BlocListener<AnonUserBloc, AnonUserState>(
            listener: (context, state) async {
              if (state.openedAnonUser != null) {
                await runAppFlowy();
              }
            },
            child: BlocBuilder<AnonUserBloc, AnonUserState>(
              builder: (context, state) {
                final text = LocaleKeys.signIn_anonymous.tr();
                final onTap = state.anonUsers.isEmpty
                    ? () {
                        context
                            .read<SignInBloc>()
                            .add(const SignInEvent.signedInAsGuest());
                      }
                    : () {
                        final bloc = context.read<AnonUserBloc>();
                        final user = bloc.state.anonUsers.first;
                        bloc.add(AnonUserEvent.openAnonUser(user));
                      };
                return FlowyButton(
                  useIntrinsicWidth: true,
                  onTap: onTap,
                  text: FlowyText(
                    text,
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
