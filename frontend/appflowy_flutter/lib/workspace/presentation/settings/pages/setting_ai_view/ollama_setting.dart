import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/ollama_setting_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OllamaSettingPage extends StatelessWidget {
  const OllamaSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          OllamaSettingBloc()..add(const OllamaSettingEvent.started()),
      child: BlocBuilder<OllamaSettingBloc, OllamaSettingState>(
        buildWhen: (previous, current) =>
            previous.inputItems != current.inputItems ||
            previous.isEdited != current.isEdited,
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: state.inputItems.length,
                  separatorBuilder: (_, __) => const VSpace(10),
                  itemBuilder: (context, index) {
                    final item = state.inputItems[index];
                    return _SettingItemWidget(item: item);
                  },
                ),
                const VSpace(6),
                _InstallOllamaInstruction(),
                _SaveButton(isEdited: state.isEdited),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingItemWidget extends StatelessWidget {
  const _SettingItemWidget({required this.item});

  final SettingItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(item.content + item.settingType.title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText(
          item.settingType.title,
          fontSize: 12,
          figmaLineHeight: 16,
        ),
        const VSpace(4),
        SizedBox(
          height: 40,
          child: FlowyTextField(
            hintText: item.hintText,
            text: item.content,
            onChanged: (content) {
              context.read<OllamaSettingBloc>().add(
                    OllamaSettingEvent.onEdit(content, item.settingType),
                  );
            },
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isEdited});

  final bool isEdited;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FlowyTooltip(
        message: isEdited ? null : 'No changes',
        child: FlowyButton(
          text: FlowyText(
            'Apply',
            figmaLineHeight: 20,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          disable: !isEdited,
          expandText: false,
          margin: EdgeInsets.all(8.0),
          backgroundColor: Theme.of(context).colorScheme.primary,
          hoverColor: Theme.of(context).colorScheme.primary.withAlpha(200),
          onTap: () {
            if (isEdited) {
              context
                  .read<OllamaSettingBloc>()
                  .add(const OllamaSettingEvent.submit());
            }
          },
        ),
      ),
    );
  }
}

class _InstallOllamaInstruction extends StatelessWidget {
  const _InstallOllamaInstruction();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontSize: 12, height: 1.5);
    return RichText(
      maxLines: 3,
      textAlign: TextAlign.left,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: LocaleKeys.settings_aiPage_keys_localAISetupInstruction1.tr(),
            style: textStyle?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          TextSpan(
            text:
                " ${LocaleKeys.settings_aiPage_keys_localAISetupInstruction2.tr()} ",
            style: textStyle?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => afLaunchUrlString(
                    "https://appflowy.com/guide/appflowy-local-ai-ollama",
                  ),
          ),
          TextSpan(
            text: LocaleKeys.settings_aiPage_keys_localAISetupInstruction3.tr(),
            style: textStyle?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
