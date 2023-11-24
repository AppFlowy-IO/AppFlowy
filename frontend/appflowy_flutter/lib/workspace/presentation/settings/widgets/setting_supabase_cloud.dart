import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/supabase_cloud_setting_bloc.dart';
import 'package:appflowy/workspace/application/settings/supabase_cloud_urls_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingSupabaseCloudView extends StatelessWidget {
  final VoidCallback didResetServerUrl;
  const SettingSupabaseCloudView({required this.didResetServerUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<CloudSettingPB, FlowyError>>(
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
                      didUpdateUrls: didResetServerUrl,
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
  final VoidCallback didUpdateUrls;
  const SupabaseCloudURLs({
    required this.didUpdateUrls,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupabaseCloudURLsBloc(),
      child: BlocListener<SupabaseCloudURLsBloc, SupabaseCloudURLsState>(
        listener: (context, state) {
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
                  error: state.urlError.fold(() => null, (a) => a),
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
                  error: state.anonKeyError.fold(() => null, (a) => a),
                ),
                const VSpace(20),
                FlowyButton(
                  isSelected: true,
                  useIntrinsicWidth: true,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  text: FlowyText(
                    LocaleKeys.settings_menu_restartApp.tr(),
                  ),
                  onTap: () {
                    NavigatorAlertDialog(
                      title: LocaleKeys.settings_menu_restartAppTip.tr(),
                      confirm: () => context
                          .read<SupabaseCloudURLsBloc>()
                          .add(const SupabaseCloudURLsEvent.confirmUpdate()),
                    ).show(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
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
        );

        return Column(
          children: [
            Row(
              children: [
                FlowyText.medium(LocaleKeys.settings_menu_enableEncrypt.tr()),
                const Spacer(),
                indicator,
                const HSpace(3),
                Switch(
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
              mainAxisAlignment: MainAxisAlignment.start,
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
                      disable: !(state.setting.enableEncrypt),
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
            Switch(
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
  final String title;
  final String url;
  final String hint;
  final String? error;
  final Function(String) onChanged;

  const SupabaseInput({
    required this.title,
    required this.url,
    required this.hint,
    required this.onChanged,
    required this.error,
    Key? key,
  }) : super(key: key);

  @override
  SupabaseInputState createState() => SupabaseInputState();
}

class SupabaseInputState extends State<SupabaseInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
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
              BorderSide(color: Theme.of(context).colorScheme.onBackground),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class SupabaseSelfhostTip extends StatelessWidget {
  final url =
      "https://docs.appflowy.io/docs/guides/appflowy/self-hosting-appflowy-using-supabase";
  const SupabaseSelfhostTip({super.key});

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
              recognizer: TapGestureRecognizer()..onTap = () => _launchURL(),
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

  Future<void> _launchURL() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Log.error("Could not launch $url");
    }
  }
}
