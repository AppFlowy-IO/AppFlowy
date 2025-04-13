import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/anon_user_bloc.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInAnonymousButtonV3 extends StatelessWidget {
  const SignInAnonymousButtonV3({
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
                final text = LocaleKeys.signIn_anonymousMode.tr();
                final onTap = state.anonUsers.isEmpty
                    ? () {
                        context
                            .read<SignInBloc>()
                            .add(const SignInEvent.signInAsGuest());
                      }
                    : () {
                        final bloc = context.read<AnonUserBloc>();
                        final user = bloc.state.anonUsers.first;
                        bloc.add(AnonUserEvent.openAnonUser(user));
                      };
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 32),
                    maximumSize: const Size(double.infinity, 38),
                  ),
                  onPressed: onTap,
                  child: FlowyText(
                    text,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimary,
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
