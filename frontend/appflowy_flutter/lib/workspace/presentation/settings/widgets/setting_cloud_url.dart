import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/cloud_setting_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CloudURLConfiguration extends StatelessWidget {
  const CloudURLConfiguration({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppFlowyCloudSettingBloc()
        ..add(const AppFlowyCloudSettingEvent.initial()),
      child: BlocListener<AppFlowyCloudSettingBloc, AppFlowyCloudSettingState>(
        listenWhen: (previous, current) =>
            previous.successOrFailure != current.successOrFailure,
        listener: (context, state) {
          state.successOrFailure.fold(
            (l) => null,
            (r) {
              // show error
            },
          );
        },
        child: BlocBuilder<AppFlowyCloudSettingBloc, AppFlowyCloudSettingState>(
          builder: (context, state) {
            return Column(
              children: [
                CloudURLInput(
                  title: LocaleKeys.settings_menu_cloudURL.tr(),
                  url: state.config.base_url,
                  hint: LocaleKeys.settings_menu_cloudURLHint.tr(),
                  onChanged: (text) {
                    context
                        .read<AppFlowyCloudSettingBloc>()
                        .add(AppFlowyCloudSettingEvent.updateServerUrl(text));
                  },
                ),
                const VSpace(6),
                CloudURLInput(
                  title: LocaleKeys.settings_menu_cloudWSURL.tr(),
                  url: state.config.ws_base_url,
                  hint: LocaleKeys.settings_menu_cloudWSURLHint.tr(),
                  onChanged: (text) {
                    context.read<AppFlowyCloudSettingBloc>().add(
                        AppFlowyCloudSettingEvent.updateWebsocketUrl(text));
                  },
                ),
                const VSpace(20),
                FlowyButton(
                  useIntrinsicWidth: true,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  text: FlowyText(
                    LocaleKeys.settings_menu_save.tr(),
                  ),
                  onTap: () {
                    NavigatorAlertDialog(
                      title: LocaleKeys.settings_menu_restartAppTip.tr(),
                      confirm: () async {
                        context.read<AppFlowyCloudSettingBloc>().add(
                            const AppFlowyCloudSettingEvent.confirmUpdate());
                      },
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

@visibleForTesting
class CloudURLInput extends StatefulWidget {
  final String title;
  final String url;
  final String hint;
  final Function(String) onChanged;

  const CloudURLInput({
    required this.title,
    required this.url,
    required this.hint,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  CloudURLInputState createState() => CloudURLInputState();
}

class CloudURLInputState extends State<CloudURLInput> {
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
