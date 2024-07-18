import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_chat_bloc.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_chat_toggle_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/downloading.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/init_local_ai.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/plugin_state.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-chat/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocalAIChatSetting extends StatelessWidget {
  const LocalAIChatSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LocalAIChatSettingBloc()),
        BlocProvider(
          create: (context) => LocalAIChatToggleBloc()
            ..add(const LocalAIChatToggleEvent.started()),
        ),
      ],
      child: ExpandableNotifier(
        child: BlocListener<LocalAIChatToggleBloc, LocalAIChatToggleState>(
          listener: (context, state) {
            // Listen to the toggle state and expand the panel if the state is ready.
            final controller = ExpandableController.of(
              context,
              required: true,
            )!;

            // Neet to wrap with WidgetsBinding.instance.addPostFrameCallback otherwise the
            // ExpandablePanel not expanded sometimes. Maybe because the ExpandablePanel is not
            // built yet when the listener is called.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) {
                state.pageIndicator.when(
                  error: (_) => controller.expanded = false,
                  ready: (enabled) {
                    controller.expanded = enabled;
                    context.read<LocalAIChatSettingBloc>().add(
                          const LocalAIChatSettingEvent.refreshAISetting(),
                        );
                  },
                  loading: () => controller.expanded = false,
                );
              },
              debugLabel: 'LocalAI.showLocalAIChatSetting',
            );
          },
          child: ExpandablePanel(
            theme: const ExpandableThemeData(
              headerAlignment: ExpandablePanelHeaderAlignment.center,
              tapBodyToCollapse: false,
              hasIcon: false,
              tapBodyToExpand: false,
              tapHeaderToExpand: false,
            ),
            header: const LocalAIChatSettingHeader(),
            collapsed: const SizedBox.shrink(),
            expanded: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      BlocBuilder<LocalAIChatSettingBloc,
                          LocalAIChatSettingState>(
                        builder: (context, state) {
                          return state.fetchModelInfoState.when(
                            loading: () => Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: FlowyText(
                                      LocaleKeys
                                          .settings_aiPage_keys_fetchLocalModel
                                          .tr(),
                                    ),
                                  ),
                                  const Spacer(),
                                  const CircularProgressIndicator.adaptive(),
                                ],
                              ),
                            ),
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
          ),
        ),
      ),
    );
  }
}

class LocalAIChatSettingHeader extends StatelessWidget {
  const LocalAIChatSettingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAIChatToggleBloc, LocalAIChatToggleState>(
      builder: (context, state) {
        return state.pageIndicator.when(
          error: (error) {
            return const SizedBox.shrink();
          },
          loading: () {
            return Row(
              children: [
                FlowyText(
                  LocaleKeys.settings_aiPage_keys_localAIStart.tr(),
                ),
                const Spacer(),
                const CircularProgressIndicator.adaptive(),
                const HSpace(8),
              ],
            );
          },
          ready: (isEnabled) {
            return Row(
              children: [
                const FlowyText('Enable Local AI Chat'),
                const Spacer(),
                Toggle(
                  value: isEnabled,
                  onChanged: (value) {
                    context
                        .read<LocalAIChatToggleBloc>()
                        .add(const LocalAIChatToggleEvent.toggle());
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SelectLocalModelDropdownMenu extends StatelessWidget {
  const _SelectLocalModelDropdownMenu();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAIChatSettingBloc, LocalAIChatSettingState>(
      builder: (context, state) {
        return Flexible(
          child: SettingsDropdown<LLMModelPB>(
            key: const Key('_SelectLocalModelDropdownMenu'),
            onChanged: (model) => context.read<LocalAIChatSettingBloc>().add(
                  LocalAIChatSettingEvent.selectLLMConfig(model),
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
    return BlocBuilder<LocalAIChatSettingBloc, LocalAIChatSettingState>(
      builder: (context, state) {
        final error = errorFromState(state);
        if (error == null) {
          // If the error is null, handle selected llm model.
          if (state.localAIInfo != null) {
            final child = state.localAIInfo!.when(
              requestDownloadInfo: (
                LocalModelResourcePB llmResource,
                LLMModelPB llmModel,
              ) {
                _showDownloadDialog(context, llmResource, llmModel);
                return const SizedBox.shrink();
              },
              showDownload: (
                LocalModelResourcePB llmResource,
                LLMModelPB llmModel,
              ) =>
                  _ShowDownloadIndicator(
                llmResource: llmResource,
                llmModel: llmModel,
              ),
              startDownloading: (llmModel) {
                return DownloadingIndicator(
                  key: UniqueKey(),
                  llmModel: llmModel,
                  onFinish: () => context
                      .read<LocalAIChatSettingBloc>()
                      .add(const LocalAIChatSettingEvent.finishDownload()),
                  onCancel: () => context
                      .read<LocalAIChatSettingBloc>()
                      .add(const LocalAIChatSettingEvent.cancelDownload()),
                );
              },
              finishDownload: () => const InitLocalAIIndicator(),
              checkPluginState: () => const CheckPluginStateIndicator(),
            );

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: child,
            );
          } else {
            return const SizedBox.shrink();
          }
        } else {
          return Opacity(
            opacity: 0.5,
            child: FlowyText(
              error.msg,
              maxLines: 10,
            ),
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
                context.read<LocalAIChatSettingBloc>().add(
                      LocalAIChatSettingEvent.startDownloadModel(
                        llmModel,
                      ),
                    );
              },
              onCancelPressed: () {
                context.read<LocalAIChatSettingBloc>().add(
                      const LocalAIChatSettingEvent.cancelDownload(),
                    );
              },
            );
          },
        );
      },
      debugLabel: 'localModel.download',
    );
  }

  FlowyError? errorFromState(LocalAIChatSettingState state) {
    final err = state.fetchModelInfoState.when(
      loading: () => null,
      finish: (err) => err,
    );

    if (err == null) {
      state.selectLLMState.when(
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

class _ShowDownloadIndicator extends StatelessWidget {
  const _ShowDownloadIndicator({
    required this.llmResource,
    required this.llmModel,
  });
  final LocalModelResourcePB llmResource;
  final LLMModelPB llmModel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalAIChatSettingBloc, LocalAIChatSettingState>(
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
                            context.read<LocalAIChatSettingBloc>().add(
                                  LocalAIChatSettingEvent.startDownloadModel(
                                    llmModel,
                                  ),
                                );
                          },
                          onCancelPressed: () {
                            context.read<LocalAIChatSettingBloc>().add(
                                  const LocalAIChatSettingEvent
                                      .cancelDownload(),
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
