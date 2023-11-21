import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class CloudURLConfiguration extends StatelessWidget {
  const CloudURLConfiguration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CloudURLInput(
          title: LocaleKeys.settings_menu_cloudBaseURL.tr(),
          url: "https://appflowy.com",
        ),
        const VSpace(6),
        CloudURLInput(
          title: LocaleKeys.settings_menu_cloudWSBaseURL.tr(),
          url: "https://appflowy.com",
        ),
        const VSpace(6),
        CloudURLInput(
          title: LocaleKeys.settings_menu_gotrueURL.tr(),
          url: "https://appflowy.com",
        ),
        const VSpace(20),
        Tooltip(
          message: LocaleKeys.settings_menu_restartAppTip.tr(),
          child: FlowyButton(
            useIntrinsicWidth: true,
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            text: FlowyText(
              LocaleKeys.settings_menu_save.tr(),
            ),
            onTap: () {
              NavigatorAlertDialog(
                title: LocaleKeys.settings_menu_restartAppTip.tr(),
                confirm: () async {},
              ).show(context);
            },
          ),
        ),
      ],
    );
  }
}

@visibleForTesting
class CloudURLInput extends StatefulWidget {
  final String title;
  final String url;

  const CloudURLInput({
    required this.title,
    required this.url,
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
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        labelText: widget.title,
        labelStyle: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(fontWeight: FontWeight.w500),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.onBackground),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      onChanged: (val) {},
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
