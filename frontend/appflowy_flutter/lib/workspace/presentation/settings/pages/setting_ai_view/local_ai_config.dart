import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/downloading.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/init_local_ai.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/plugin_state.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocalModelConfig extends StatelessWidget {
  const LocalModelConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsAIBloc, SettingsAIState>(
      builder: (context, state) {
        if (state.aiSettings == null) {
          return const SizedBox.shrink();
        }

        if (state.aiSettings!.aiModel != AIModelPB.LocalAIModel) {
          return const SizedBox.shrink();
        }

        return BlocProvider(
          create: (context) =>
              LocalAIConfigBloc()..add(const LocalAIConfigEvent.started()),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FlowyText.medium(
                        LocaleKeys.settings_aiPage_keys_llmModel.tr(),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    BlocBuilder<LocalAIConfigBloc, LocalAIConfigState>(
                      builder: (context, state) {
                        return state.loadingState.when(
                          loading: () =>
                              const CircularProgressIndicator.adaptive(),
                          finish: (err) {
                            return (err == null)
                                ? const _SelectLocalModelDropdownMenu()
                                : const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ],
                ),
                const IntrinsicHeight(child: _LocalLLMInfoWidget()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectLocalModelDropdownMenu extends StatelessWidget {
  const _SelectLocalModelDropdownMenu();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAIConfigBloc, LocalAIConfigState>(
      builder: (context, state) {
        return Flexible(
          child: SettingsDropdown<LLMModelPB>(
            key: const Key('_SelectLocalModelDropdownMenu'),
            onChanged: (model) => context.read<LocalAIConfigBloc>().add(
                  LocalAIConfigEvent.selectLLMConfig(model),
                ),
            selectedOption: state.selectedLLMModel!,
            options: state.models
                .map(
                  (llm) => buildDropdownMenuEntry<LLMModelPB>(
                    context,
                    value: llm,
                    label: llm.chatModel,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _LocalLLMInfoWidget extends StatelessWidget {
  const _LocalLLMInfoWidget();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAIConfigBloc, LocalAIConfigState>(
      builder: (context, state) {
        final error = errorFromState(state);
        if (error == null) {
          // If the error is null, handle selected llm model.
          if (state.localAIInfo != null) {
            final child = state.localAIInfo!.when(
              requestDownload: (
                LocalModelResourcePB llmResource,
                LLMModelPB llmModel,
              ) {
                _showDownloadDialog(context, llmResource, llmModel);
                return const SizedBox.shrink();
              },
              downloadNeeded: (
                LocalModelResourcePB llmResource,
                LLMModelPB llmModel,
              ) =>
                  _ModelNotExistIndicator(
                llmResource: llmResource,
                llmModel: llmModel,
              ),
              downloading: (llmModel) {
                return DownloadingIndicator(
                  key: UniqueKey(),
                  llmModel: llmModel,
                  onFinish: () => context
                      .read<LocalAIConfigBloc>()
                      .add(const LocalAIConfigEvent.finishDownload()),
                  onCancel: () => context
                      .read<LocalAIConfigBloc>()
                      .add(const LocalAIConfigEvent.cancelDownload()),
                );
              },
              pluginState: () => const PluginStateIndicator(),
              finishDownload: () => const InitLocalAIIndicator(),
            );

            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: child,
            );
          } else {
            return const SizedBox.shrink();
          }
        } else {
          return FlowyText(
            error.msg,
            maxLines: 10,
          );
        }
      },
    );
  }

  void _showDownloadDialog(
    BuildContext context,
    LocalModelResourcePB llmResource,
    LLMModelPB llmModel,
  ) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: false,
          builder: (dialogContext) {
            return _LLMModelDownloadDialog(
              llmResource: llmResource,
              onOkPressed: () {
                context.read<LocalAIConfigBloc>().add(
                      LocalAIConfigEvent.startDownloadModel(
                        llmModel,
                      ),
                    );
              },
              onCancelPressed: () {
                context.read<LocalAIConfigBloc>().add(
                      const LocalAIConfigEvent.cancelDownload(),
                    );
              },
            );
          },
        );
      },
      debugLabel: 'localModel.download',
    );
  }

  FlowyError? errorFromState(LocalAIConfigState state) {
    final err = state.loadingState.when(
      loading: () => null,
      finish: (err) => err,
    );

    if (err == null) {
      state.llmModelLoadingState.when(
        loading: () => null,
        finish: (err) => err,
      );
    }

    return err;
  }
}

class _LLMModelDownloadDialog extends StatelessWidget {
  const _LLMModelDownloadDialog({
    required this.llmResource,
    required this.onOkPressed,
    required this.onCancelPressed,
  });
  final LocalModelResourcePB llmResource;
  final VoidCallback onOkPressed;
  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    return NavigatorOkCancelDialog(
      title: LocaleKeys.settings_aiPage_keys_downloadLLMPrompt.tr(
        args: [
          llmResource.pendingResources[0].name,
        ],
      ),
      message: llmResource.pendingResources[0].fileSize == 0
          ? ""
          : LocaleKeys.settings_aiPage_keys_downloadLLMPromptDetail.tr(
              args: [
                llmResource.pendingResources[0].name,
                llmResource.pendingResources[0].fileSize.toString(),
              ],
            ),
      okTitle: LocaleKeys.button_confirm.tr(),
      cancelTitle: LocaleKeys.button_cancel.tr(),
      onOkPressed: onOkPressed,
      onCancelPressed: onCancelPressed,
      titleUpperCase: false,
    );
  }
}

class _ModelNotExistIndicator extends StatelessWidget {
  const _ModelNotExistIndicator({
    required this.llmResource,
    required this.llmModel,
  });
  final LocalModelResourcePB llmResource;
  final LLMModelPB llmModel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAIConfigBloc, LocalAIConfigState>(
      builder: (context, state) {
        return Row(
          children: [
            const Spacer(),
            IntrinsicWidth(
              child: SizedBox(
                height: 30,
                child: FlowyButton(
                  text: FlowyText(
                    LocaleKeys.settings_aiPage_keys_downloadAIModelButton.tr(),
                    fontSize: 14,
                    color: const Color(0xFF005483),
                  ),
                  leftIcon: const FlowySvg(
                    FlowySvgs.local_model_download_s,
                    color: Color(0xFF005483),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      useRootNavigator: false,
                      builder: (dialogContext) {
                        return _LLMModelDownloadDialog(
                          llmResource: llmResource,
                          onOkPressed: () {
                            context.read<LocalAIConfigBloc>().add(
                                  LocalAIConfigEvent.startDownloadModel(
                                    llmModel,
                                  ),
                                );
                          },
                          onCancelPressed: () {
                            context.read<LocalAIConfigBloc>().add(
                                  const LocalAIConfigEvent.cancelDownload(),
                                );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
