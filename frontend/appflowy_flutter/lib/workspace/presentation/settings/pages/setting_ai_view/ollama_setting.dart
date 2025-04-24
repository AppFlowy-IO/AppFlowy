import 'package:appflowy/workspace/application/settings/ai/ollama_setting_bloc.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
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
              spacing: 10,
              children: [
                for (final item in state.inputItems)
                  _SettingItemWidget(item: item),
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
          height: 32,
          child: FlowyTextField(
            autoFocus: false,
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
        child: SizedBox(
          child: FlowyButton(
            text: FlowyText(
              'Apply',
              figmaLineHeight: 20,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            disable: !isEdited,
            expandText: false,
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
      ),
    );
  }
}
