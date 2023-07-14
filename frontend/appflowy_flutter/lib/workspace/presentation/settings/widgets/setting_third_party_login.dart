import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/sign_in_screen.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingThirdPartyLogin extends StatelessWidget {
  const SettingThirdPartyLogin({super.key});

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
        builder: (_, __) => const ThirdPartySignInButtons(),
      ),
    );
  }

  void _handleSuccessOrFail(
    Either<UserProfilePB, FlowyError> result,
    BuildContext context,
  ) {
    result.fold(
      (user) {
        // TODO(Lucas): push to home screen
      },
      (error) => showSnapBar(context, error.msg),
    );
  }
}
