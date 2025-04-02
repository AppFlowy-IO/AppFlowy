import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/anon_user_bloc.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class ChangeCloudModeButton extends StatelessWidget {
  const ChangeCloudModeButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      useIntrinsicWidth: true,
      text: FlowyText(
        'Cloud',
        decoration: TextDecoration.underline,
        color: Colors.grey,
        fontSize: 12,
      ),
      onTap: () async {
        await useAppFlowyBetaCloudWithURL(
          kAppflowyCloudUrl,
          AuthenticatorType.appflowyCloud,
        );
        await runAppFlowy();
      },
    );
  }
}
