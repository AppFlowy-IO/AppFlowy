import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/field/field_controller.dart';
import '../../../application/filter/filter_create_bloc.dart';

class SettingSupabaseCloudView extends StatelessWidget {
  const SettingSupabaseCloudView({required this.restartAppFlowy, super.key});

  final VoidCallback restartAppFlowy;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlowyResult<CloudSettingPB, FlowyError>>(
      future: UserEventGetCloudConfig().send(),
      builder: (context, snapshot) {
        if (snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
          return snapshot.data!.fold(
            (setting) {
              return BlocProvider(
                create: (context) => SupabaseCloudSettingBloc(
                  setting: setting,
                )..add(const SupabaseCloudSettingEvent.initial()),
                child: Column(
                  children: [
                    BlocBuilder<SupabaseCloudSettingBloc,
                        SupabaseCloudSettingState>(
                      builder: (context, state) {
                        return const Column(
                          children: [
                            SupabaseEnableSync(),
                            EnableEncrypt(),
                          ],
                        );
                      },
                    ),
                    const VSpace(40),
                    const SupabaseSelfhostTip(),
                    SupabaseCloudURLs(
                      didUpdateUrls: restartAppFlowy,
                    ),
                  ],
                ),
              );
            },
            (err) {
              return FlowyErrorPage.message(err.toString(), howToFix: "");
            },
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class SupabaseCloudURLs extends StatelessWidget {
  const SupabaseCloudURLs({super.key, required this.didUpdateUrls});

  final VoidCallback didUpdateUrls;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupabaseCloudURLsBloc(),
      child: BlocListener<SupabaseCloudURLsBloc, SupabaseCloudURLsState>(
        listener: (context, state) async {
          if (state.restartApp) {
            didUpdateUrls();
          }
        },
        child: BlocBuilder<SupabaseCloudURLsBloc, SupabaseCloudURLsState>(
          builder: (context, state) {
            return Column(
              children: [
                SupabaseInput(
                  title: LocaleKeys.settings_menu_cloudSupabaseUrl.tr(),
                  url: state.config.url,
                  hint: LocaleKeys.settings_menu_cloudURLHint.tr(),
                  onChanged: (text) {
                    context
                        .read<SupabaseCloudURLsBloc>()
                        .add(SupabaseCloudURLsEvent.updateUrl(text));
                  },
                  error: state.urlError,
                ),
                SupabaseInput(
                  title: LocaleKeys.settings_menu_cloudSupabaseAnonKey.tr(),
                  url: state.config.anon_key,
                  hint: LocaleKeys.settings_menu_cloudURLHint.tr(),
                  onChanged: (text) {
                    context
                        .read<SupabaseCloudURLsBloc>()
                        .add(SupabaseCloudURLsEvent.updateAnonKey(text));
                  },
                  error: state.anonKeyError,
                ),
                const VSpace(20),
                RestartButton(
                  onClick: () => _restartApp(context),
                  showRestartHint: state.showRestartHint,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _restartApp(BuildContext context) {
    NavigatorAlertDialog(
      title: LocaleKeys.settings_menu_restartAppTip.tr(),
      confirm: () => context
          .read<SupabaseCloudURLsBloc>()
          .add(const SupabaseCloudURLsEvent.confirmUpdate()),
    ).show(context);
  }
}

class EnableEncrypt extends StatelessWidget {
  const EnableEncrypt({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupabaseCloudSettingBloc, SupabaseCloudSettingState>(
      builder: (context, state) {
        final indicator = state.loadingState.when(
          loading: () => const CircularProgressIndicator.adaptive(),
          finish: (successOrFail) => const SizedBox.shrink(),
          idle: () => const SizedBox.shrink(),
        );

        return Column(
          children: [
            Row(
              children: [
                FlowyText.medium(LocaleKeys.settings_menu_enableEncrypt.tr()),
                const Spacer(),
                indicator,
                const HSpace(3),
                Switch.adaptive(
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: state.setting.enableEncrypt
                      ? null
                      : (bool value) {
                          context.read<SupabaseCloudSettingBloc>().add(
                                SupabaseCloudSettingEvent.enableEncrypt(value),
                              );
                        },
                  value: state.setting.enableEncrypt,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Opacity(
                    opacity: 0.6,
                    child: FlowyText.medium(
                      LocaleKeys.settings_menu_enableEncryptPrompt.tr(),
                      maxLines: 13,
                    ),
                  ),
                ),
                const VSpace(6),
                SizedBox(
                  height: 40,
                  child: FlowyTooltip(
                    message: LocaleKeys.settings_menu_clickToCopySecret.tr(),
                    child: FlowyButton(
                      disable: !state.setting.enableEncrypt,
                      decoration: BoxDecoration(
                        borderRadius: Corners.s5Border,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      text: FlowyText.medium(state.setting.encryptSecret),
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: state.setting.encryptSecret),
                        );
                        showMessageToast(LocaleKeys.message_copy_success.tr());
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class SupabaseEnableSync extends StatelessWidget {
  const SupabaseEnableSync({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupabaseCloudSettingBloc, SupabaseCloudSettingState>(
      builder: (context, state) {
        return Row(
          children: [
            FlowyText.medium(LocaleKeys.settings_menu_enableSync.tr()),
            const Spacer(),
            Switch.adaptive(
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (bool value) {
                context.read<SupabaseCloudSettingBloc>().add(
                      SupabaseCloudSettingEvent.enableSync(value),
                    );
              },
              value: state.setting.enableSync,
            ),
          ],
        );
      },
    );
  }
}

@visibleForTesting
class SupabaseInput extends StatefulWidget {
  const SupabaseInput({
    super.key,
    required this.title,
    required this.url,
    required this.hint,
    required this.error,
    required this.onChanged,
  });

  final String title;
  final String url;
  final String hint;
  final String? error;
  final Function(String) onChanged;

  @override
  SupabaseInputState createState() => SupabaseInputState();
}

class SupabaseInputState extends State<SupabaseInput> {
  late final _controller = TextEditingController(text: widget.url);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(fontSize: 12.0),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        labelText: widget.title,
        labelStyle: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(fontWeight: FontWeight.w400, fontSize: 16),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: AFThemeExtension.of(context).onBackground),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        hintText: widget.hint,
        errorText: widget.error,
      ),
      onChanged: widget.onChanged,
    );
  }
}

class SupabaseSelfhostTip extends StatelessWidget {
  const SupabaseSelfhostTip({super.key});

  final url =
      "https://docs.appflowy.io/docs/guides/appflowy/self-hosting-appflowy-using-supabase";

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: LocaleKeys.settings_menu_selfHostStart.tr(),
              style: Theme.of(context).textTheme.bodySmall!,
            ),
            TextSpan(
              text: " ${LocaleKeys.settings_menu_selfHostContent.tr()} ",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: FontSizes.s14,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => afLaunchUrlString(url),
            ),
            TextSpan(
              text: LocaleKeys.settings_menu_selfHostEnd.tr(),
              style: Theme.of(context).textTheme.bodySmall!,
            ),
          ],
        ),
      ),
    );
  }
}
