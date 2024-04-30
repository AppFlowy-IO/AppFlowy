import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileLoadingScreen extends StatelessWidget {
  const MobileLoadingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 16;

    return Scaffold(
      appBar: FlowyAppBar(
        showDivider: false,
        onTapLeading: () => context.read<SignInBloc>().add(
              const SignInEvent.cancel(),
            ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlowyText(LocaleKeys.signIn_signingInText.tr()),
            const VSpace(spacing),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
