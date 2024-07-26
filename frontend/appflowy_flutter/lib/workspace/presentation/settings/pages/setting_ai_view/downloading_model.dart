import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/download_model_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DownloadingIndicator extends StatelessWidget {
  const DownloadingIndicator({
    required this.llmModel,
    required this.onCancel,
    required this.onFinish,
    super.key,
  });
  final LLMModelPB llmModel;
  final VoidCallback onCancel;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DownloadModelBloc(llmModel)..add(const DownloadModelEvent.started()),
      child: BlocListener<DownloadModelBloc, DownloadModelState>(
        listener: (context, state) {
          if (state.isFinish) {
            onFinish();
          }
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              DownloadingProgressBar(onCancel: onCancel),
            ],
          ),
        ),
      ),
    );
  }
}

class DownloadingProgressBar extends StatelessWidget {
  const DownloadingProgressBar({required this.onCancel, super.key});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadModelBloc, DownloadModelState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.6,
              child: FlowyText(
                "${LocaleKeys.settings_aiPage_keys_downloadingModel.tr()}: ${state.object}",
                fontSize: 11,
              ),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: LinearPercentIndicator(
                      lineHeight: 9.0,
                      percent: state.percent,
                      padding: EdgeInsets.zero,
                      progressColor: AFThemeExtension.of(context).success,
                      backgroundColor:
                          AFThemeExtension.of(context).progressBarBGColor,
                      barRadius: const Radius.circular(8),
                      trailing: FlowyText(
                        "${(state.percent * 100).toStringAsFixed(0)}%",
                        fontSize: 11,
                        color: AFThemeExtension.of(context).success,
                      ),
                    ),
                  ),
                  const HSpace(12),
                  FlowyButton(
                    useIntrinsicWidth: true,
                    text: FlowyText(
                      LocaleKeys.button_cancel.tr(),
                      fontSize: 11,
                    ),
                    onTap: onCancel,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
