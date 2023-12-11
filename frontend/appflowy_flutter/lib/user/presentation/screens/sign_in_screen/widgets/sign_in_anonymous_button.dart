import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/historical_user_bloc.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInAnonymousButton extends StatelessWidget {
  /// Used in DesktopSignInScreen and MobileSignInScreen
  const SignInAnonymousButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = PlatformExtension.isMobile;

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
                    ? LocaleKeys.signIn_loginStartWithAnonymous.tr()
                    : LocaleKeys.signIn_continueAnonymousUser.tr();
                final onTap = state.historicalUsers.isEmpty
                    ? () {
                        context
                            .read<SignInBloc>()
                            .add(const SignInEvent.signedInAsGuest());
                      }
                    : () {
                        final bloc = context.read<HistoricalUserBloc>();
                        final user = bloc.state.historicalUsers.first;
                        bloc.add(HistoricalUserEvent.openHistoricalUser(user));
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
