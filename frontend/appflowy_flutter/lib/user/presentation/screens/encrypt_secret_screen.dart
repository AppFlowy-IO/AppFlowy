import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/presentation/helpers/helpers.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/encrypt_secret_bloc.dart';

class EncryptSecretScreen extends StatefulWidget {
  const EncryptSecretScreen({required this.user, super.key});

  final UserProfilePB user;

  static const routeName = '/EncryptSecretScreen';

  // arguments used in GoRouter
  static const argUser = 'user';
  static const argKey = 'key';

  @override
  State<EncryptSecretScreen> createState() => _EncryptSecretScreenState();
}

class _EncryptSecretScreenState extends State<EncryptSecretScreen> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => EncryptSecretBloc(user: widget.user),
        child: MultiBlocListener(
          listeners: [
            BlocListener<EncryptSecretBloc, EncryptSecretState>(
              listenWhen: (previous, current) =>
                  previous.isSignOut != current.isSignOut,
              listener: (context, state) async {
                if (state.isSignOut) {
                  await runAppFlowy();
                }
              },
            ),
            BlocListener<EncryptSecretBloc, EncryptSecretState>(
              listenWhen: (previous, current) =>
                  previous.successOrFail != current.successOrFail,
              listener: (context, state) async {
                await state.successOrFail?.fold(
                  (unit) async {
                    await runAppFlowy();
                  },
                  (error) {
                    handleOpenWorkspaceError(context, error);
                  },
                );
              },
            ),
          ],
          child: BlocBuilder<EncryptSecretBloc, EncryptSecretState>(
            builder: (context, state) {
              final indicator = state.loadingState?.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    finish: (result) => const SizedBox.shrink(),
                    idle: () => const SizedBox.shrink(),
                  ) ??
                  const SizedBox.shrink();
              return Center(
                child: SizedBox(
                  width: 300,
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: 0.6,
                        child: FlowyText.medium(
                          "${LocaleKeys.settings_menu_inputEncryptPrompt.tr()} ${widget.user.email}",
                          fontSize: 14,
                          maxLines: 10,
                        ),
                      ),
                      const VSpace(6),
                      SizedBox(
                        width: 300,
                        child: FlowyTextField(
                          controller: _textEditingController,
                          hintText:
                              LocaleKeys.settings_menu_inputTextFieldHint.tr(),
                          onChanged: (_) {},
                        ),
                      ),
                      OkCancelButton(
                        alignment: MainAxisAlignment.end,
                        onOkPressed: () =>
                            context.read<EncryptSecretBloc>().add(
                                  EncryptSecretEvent.setEncryptSecret(
                                    _textEditingController.text,
                                  ),
                                ),
                        onCancelPressed: () => context
                            .read<EncryptSecretBloc>()
                            .add(const EncryptSecretEvent.cancelInputSecret()),
                        mode: TextButtonMode.normal,
                      ),
                      const VSpace(6),
                      indicator,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
