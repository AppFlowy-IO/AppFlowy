import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/historical_user_bloc.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInAnonymousButton extends StatelessWidget {
  final bool isMobile;

  /// Used in DesktopSignInScreen and MobileSignInScreen
  const SignInAnonymousButton({
    Key? key,
    required this.isMobile,
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
                    ? LocaleKeys.signIn_loginStartWithAnonymous.tr()
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
                // mobile
                if (isMobile) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    onPressed: onTap,
                    child: Text(LocaleKeys.signIn_loginStartWithAnonymous.tr()),
                  );
                }
                // desktop
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
