import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/anon_user_bloc.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
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
                final theme = AppFlowyTheme.of(context);
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
                return AFGhostIconTextButton(
                  text: LocaleKeys.signIn_anonymousMode.tr(),
                  textColor: (context, isHovering, disabled) {
                    return theme.textColorScheme.secondary;
                  },
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.m,
                    vertical: theme.spacing.xs,
                  ),
                  size: AFButtonSize.s,
                  onTap: onTap,
                  iconBuilder: (context, isHovering, disabled) {
                    return FlowySvg(
                      FlowySvgs.anonymous_mode_m,
                      color: theme.textColorScheme.secondary,
                    );
                  },
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
    final theme = AppFlowyTheme.of(context);
    return AFGhostIconTextButton(
      text: 'Cloud',
      textColor: (context, isHovering, disabled) {
        return theme.textColorScheme.secondary;
      },
      size: AFButtonSize.s,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.xs,
      ),
      onTap: () async {
        await useAppFlowyBetaCloudWithURL(
          kAppflowyCloudUrl,
          AuthenticatorType.appflowyCloud,
        );
        await runAppFlowy();
      },
      iconBuilder: (context, isHovering, disabled) {
        return FlowySvg(
          FlowySvgs.settings_s,
          size: Size.square(20),
          color: theme.textColorScheme.secondary,
        );
      },
    );
  }
}
