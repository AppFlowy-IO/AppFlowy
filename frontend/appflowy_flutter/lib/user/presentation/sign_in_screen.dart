import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/historical_user_bloc.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/widgets/background.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    super.key,
    required this.router,
  });

  final AuthRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          state.successOrFail.fold(
            () => null,
            (result) => _handleSuccessOrFail(result, context),
          );
        },
        builder: (_, __) => Scaffold(
          appBar: const PreferredSize(
            preferredSize: Size(double.infinity, 60),
            child: MoveWindowDetector(),
          ),
          body: SignInForm(router: router),
        ),
      ),
    );
  }

  void _handleSuccessOrFail(
    Either<UserProfilePB, FlowyError> result,
    BuildContext context,
  ) {
    result.fold(
      (user) {
        if (user.encryptionType == EncryptionTypePB.Symmetric) {
          router.pushEncryptionScreen(context, user);
        } else {
          router.pushHomeScreen(context, user);
        }
      },
      (error) {
        handleOpenWorkspaceError(context, error);
      },
    );
  }
}

void handleOpenWorkspaceError(BuildContext context, FlowyError error) {
  Log.error(error);
  switch (error.code) {
    case ErrorCode.WorkspaceDataNotSync:
      final userFolder = UserFolderPB.fromBuffer(error.payload);
      getIt<AuthRouter>().pushWorkspaceErrorScreen(context, userFolder, error);
      break;
    case ErrorCode.InvalidEncryptSecret:
      showSnapBar(
        context,
        error.msg,
      );
      break;
    default:
      showSnapBar(
        context,
        error.msg,
        onClosed: () {
          getIt<AuthService>().signOut();
          runAppFlowy();
        },
      );
  }
}

class SignInForm extends StatelessWidget {
  const SignInForm({
    super.key,
    required this.router,
  });

  final AuthRouter router;

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.read<SignInBloc>().state.isSubmitting;
    const indicatorMinHeight = 4.0;
    return Align(
      alignment: Alignment.center,
      child: AuthFormContainer(
        children: [
          // Email.
          FlowyLogoTitle(
            title: LocaleKeys.signIn_loginTitle.tr(),
            logoSize: const Size(60, 60),
          ),
          const VSpace(30),
          // Email and password. don't support yet.
          /*
          ...[
            const EmailTextField(),
            const VSpace(5),
            const PasswordTextField(),
            const VSpace(20),
            const LoginButton(),
            const VSpace(10),

            const VSpace(10),
            SignUpPrompt(router: router),
          ],
          */

          const SignInAsGuestButton(),

          // third-party sign in.
          const VSpace(20),
          const OrContinueWith(),
          const VSpace(10),
          const ThirdPartySignInButtons(),
          const VSpace(20),
          // loading status
          ...isSubmitting
              ? [
                  const VSpace(indicatorMinHeight),
                  const LinearProgressIndicator(
                    value: null,
                    minHeight: indicatorMinHeight,
                  ),
                ]
              : [
                  const VSpace(indicatorMinHeight * 2.0)
                ], // add the same space when there's no loading status.
          // ConstrainedBox(
          //   constraints: const BoxConstraints(maxHeight: 140),
          //   child: HistoricalUserList(
          //     didOpenUser: () async {
          //       await FlowyRunner.run(
          //         FlowyApp(),
          //         integrationEnv(),
          //       );
          //     },
          //   ),
          // ),
          const VSpace(20),
        ],
      ),
    );
  }
}

class SignUpPrompt extends StatelessWidget {
  const SignUpPrompt({
    Key? key,
    required this.router,
  }) : super(key: key);

  final AuthRouter router;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlowyText.medium(
          LocaleKeys.signIn_dontHaveAnAccount.tr(),
          color: Theme.of(context).hintColor,
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          onPressed: () => router.pushSignUpScreen(context),
          child: Text(
            LocaleKeys.signUp_buttonText.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        ForgetPasswordButton(router: router),
      ],
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoundedTextButton(
      title: LocaleKeys.signIn_loginButtonText.tr(),
      height: 48,
      borderRadius: Corners.s10Border,
      onPressed: () => context
          .read<SignInBloc>()
          .add(const SignInEvent.signedInWithUserEmailAndPassword()),
    );
  }
}

class SignInAsGuestButton extends StatelessWidget {
  const SignInAsGuestButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, signInState) {
        return BlocProvider(
          create: (context) => HistoricalUserBloc()
            ..add(
              const HistoricalUserEvent.initial(),
            ),
          child: BlocListener<HistoricalUserBloc, HistoricalUserState>(
            listenWhen: (previous, current) =>
                previous.openedHistoricalUser != current.openedHistoricalUser,
            listener: (context, state) async {
              await runAppFlowy();
            },
            child: BlocBuilder<HistoricalUserBloc, HistoricalUserState>(
              builder: (context, state) {
                final text = state.historicalUsers.isEmpty
                    ? LocaleKeys.signIn_loginAsGuestButtonText.tr()
                    : LocaleKeys.signIn_continueAnonymousUser.tr();

                final onTap = state.historicalUsers.isEmpty
                    ? () {
                        getIt<KeyValueStorage>().set(KVKeys.loginType, 'local');
                        context
                            .read<SignInBloc>()
                            .add(const SignInEvent.signedInAsGuest());
                      }
                    : () {
                        final bloc = context.read<HistoricalUserBloc>();
                        final user = bloc.state.historicalUsers.first;
                        bloc.add(HistoricalUserEvent.openHistoricalUser(user));
                      };

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

class ForgetPasswordButton extends StatelessWidget {
  const ForgetPasswordButton({
    Key? key,
    required this.router,
  }) : super(key: key);

  final AuthRouter router;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: Theme.of(context).textTheme.bodyMedium,
      ),
      onPressed: () {
        throw UnimplementedError();
      },
      child: Text(
        LocaleKeys.signIn_forgotPassword.tr(),
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      buildWhen: (previous, current) =>
          previous.passwordError != current.passwordError,
      builder: (context, state) {
        return RoundedInputField(
          obscureText: true,
          obscureIcon: const FlowySvg(FlowySvgs.hide_m),
          obscureHideIcon: const FlowySvg(FlowySvgs.show_m),
          hintText: LocaleKeys.signIn_passwordHint.tr(),
          errorText: context
              .read<SignInBloc>()
              .state
              .passwordError
              .fold(() => "", (error) => error),
          onChanged: (value) => context
              .read<SignInBloc>()
              .add(SignInEvent.passwordChanged(value)),
        );
      },
    );
  }
}

class EmailTextField extends StatelessWidget {
  const EmailTextField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      buildWhen: (previous, current) =>
          previous.emailError != current.emailError,
      builder: (context, state) {
        return RoundedInputField(
          hintText: LocaleKeys.signIn_emailHint.tr(),
          errorText: context
              .read<SignInBloc>()
              .state
              .emailError
              .fold(() => "", (error) => error),
          onChanged: (value) =>
              context.read<SignInBloc>().add(SignInEvent.emailChanged(value)),
        );
      },
    );
  }
}

class OrContinueWith extends StatelessWidget {
  const OrContinueWith({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Divider(
            color: Colors.white,
            height: 10,
          ),
        ),
        FlowyText.regular('    Or continue with    '),
        Flexible(
          child: Divider(
            color: Colors.white,
            height: 10,
          ),
        ),
      ],
    );
  }
}

class ThirdPartySignInButton extends StatelessWidget {
  const ThirdPartySignInButton({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  final FlowySvgData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      height: 48,
      width: 48,
      iconPadding: const EdgeInsets.all(8.0),
      radius: Corners.s10Border,
      onPressed: onPressed,
      icon: FlowySvg(
        icon,
        blendMode: null,
      ),
    );
  }
}

class ThirdPartySignInButtons extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  const ThirdPartySignInButtons({
    this.mainAxisAlignment = MainAxisAlignment.center,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: const [
        GoogleSignUpButton(),
        // const SizedBox(width: 20),
        // ThirdPartySignInButton(
        //   icon: 'login/github-mark',
        //   onPressed: () {
        //     getIt<KeyValueStorage>().set(KVKeys.loginType, 'supabase');
        //     context
        //         .read<SignInBloc>()
        //         .add(const SignInEvent.signedInWithOAuth('github'));
        //   },
        // ),
        // const SizedBox(width: 20),
        // ThirdPartySignInButton(
        //   icon: 'login/discord-mark',
        //   onPressed: () {
        //     getIt<KeyValueStorage>().set(KVKeys.loginType, 'supabase');
        //     context
        //         .read<SignInBloc>()
        //         .add(const SignInEvent.signedInWithOAuth('discord'));
        //   },
        // ),
      ],
    );
  }
}

class GoogleSignUpButton extends StatelessWidget {
  const GoogleSignUpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ThirdPartySignInButton(
      icon: FlowySvgs.google_mark_xl,
      onPressed: () {
        getIt<KeyValueStorage>().set(KVKeys.loginType, 'supabase');
        context.read<SignInBloc>().add(
              const SignInEvent.signedInWithOAuth('google'),
            );
      },
    );
  }
}
