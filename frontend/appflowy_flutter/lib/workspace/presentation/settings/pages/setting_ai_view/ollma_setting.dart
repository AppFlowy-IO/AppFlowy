import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/ollama_setting_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InstallOllamaInstruction(),
              const VSpace(12),
              ListView.separated(
                shrinkWrap: true,
                itemCount: state.inputItems.length,
                separatorBuilder: (_, __) => const VSpace(10),
                itemBuilder: (context, index) {
                  final item = state.inputItems[index];
                  return _SettingItemWidget(item: item);
                },
              ),
              const VSpace(6),
              _SaveButton(isEdited: state.isEdited),
            ],
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
        FlowyText(item.settingType.title),
        const VSpace(8),
        FlowyTextField(
          hintText: item.hintText,
          text: item.content,
          onChanged: (content) {
            context.read<OllamaSettingBloc>().add(
                  OllamaSettingEvent.onEdit(content, item.settingType),
                );
          },
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
    final tooltipMessage = isEdited ? 'Click to apply changes' : 'No changes';
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: 120,
            child: FlowyTooltip(
              message: tooltipMessage,
              child: Opacity(
                opacity: isEdited ? 1 : 0.5,
                child: FlowyTextButton(
                  'Apply',
                  mainAxisAlignment: MainAxisAlignment.center,
                  onPressed: isEdited
                      ? () {
                          context
                              .read<OllamaSettingBloc>()
                              .add(const OllamaSettingEvent.submit());
                        }
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallOllamaInstruction extends StatelessWidget {
  const _InstallOllamaInstruction();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          maxLines: 3,
          textAlign: TextAlign.left,
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text:
                    "${LocaleKeys.settings_aiPage_keys_localAISetupInstruction1.tr()} ",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(height: 1.5),
              ),
              TextSpan(
                text:
                    " ${LocaleKeys.settings_aiPage_keys_localAISetupInstruction2.tr()} ",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: FontSizes.s14,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.5,
                    ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => afLaunchUrlString(
                        "https://docs.appflowy.io/docs/appflowy/product/appflowy-ai-ollama",
                      ),
              ),
              TextSpan(
                text:
                    " ${LocaleKeys.settings_aiPage_keys_localAISetupInstruction3.tr()} ",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
