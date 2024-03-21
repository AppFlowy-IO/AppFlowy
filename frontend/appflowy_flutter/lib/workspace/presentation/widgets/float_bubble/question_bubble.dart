import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/rust_sdk.dart';
import 'package:appflowy/workspace/application/version_checker/version_checker_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _whatIsNewUrl = "https://www.appflowy.io/what-is-new";

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 30,
      height: 30,
      child: BubbleActionList(),
    );
  }
}

class BubbleActionList extends StatefulWidget {
  const BubbleActionList({super.key});

  @override
  State<BubbleActionList> createState() => _BubbleActionListState();
}

class _BubbleActionListState extends State<BubbleActionList> {
  final popoverMutex = PopoverMutex();
  bool isOpen = false;

  Color get fontColor => isOpen
      ? Theme.of(context).colorScheme.onPrimary
      : Theme.of(context).colorScheme.tertiary;

  Color get fillColor => isOpen
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.tertiaryContainer;

  void toggle() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<PopoverAction> actions = [
      ...BubbleAction.values.map((action) => BubbleActionWrapper(action)),
      FlowyVersionDescription(popoverMutex: popoverMutex),
    ];

    return PopoverActionList<PopoverAction>(
      popoverMutex: popoverMutex,
      direction: PopoverDirection.topWithRightAligned,
      actions: actions,
      offset: const Offset(0, -8),
      constraints: const BoxConstraints(
        minWidth: 170,
        maxWidth: 225,
        maxHeight: 300,
      ),
      buildChild: (controller) {
        return FlowyTextButton(
          '?',
          tooltip: LocaleKeys.questionBubble_help.tr(),
          fontWeight: FontWeight.w600,
          fontColor: fontColor,
          fillColor: fillColor,
          hoverColor: Theme.of(context).colorScheme.primary,
          mainAxisAlignment: MainAxisAlignment.center,
          radius: Corners.s10Border,
          onPressed: () {
            toggle();
            controller.show();
          },
        );
      },
      onClosed: toggle,
      onSelected: (action, controller) {
        if (action is BubbleActionWrapper) {
          switch (action.inner) {
            case BubbleAction.whatsNews:
              afLaunchUrlString(_whatIsNewUrl);
              break;
            case BubbleAction.help:
              afLaunchUrlString("https://discord.gg/9Q2xaN37tV");
              break;
            case BubbleAction.debug:
              _DebugToast().show();
              break;
            case BubbleAction.shortcuts:
              afLaunchUrlString(
                "https://docs.appflowy.io/docs/appflowy/product/shortcuts",
              );
              break;
            case BubbleAction.markdown:
              afLaunchUrlString(
                "https://docs.appflowy.io/docs/appflowy/product/markdown",
              );
              break;
            case BubbleAction.github:
              afLaunchUrlString(
                'https://github.com/AppFlowy-IO/AppFlowy/issues/new/choose',
              );
              break;
          }
        }

        debugPrint(action.runtimeType.toString());

        controller.close();
      },
    );
  }
}

class _DebugToast {
  void show() async {
    String debugInfo = "";
    debugInfo += await _getDeviceInfo();
    debugInfo += await _getDocumentPath();
    await Clipboard.setData(ClipboardData(text: debugInfo));

    showMessageToast(LocaleKeys.questionBubble_debug_success.tr());
  }

  Future<String> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = await deviceInfoPlugin.deviceInfo;

    return deviceInfo.data.entries
        .fold('', (prev, el) => "$prev${el.key}: ${el.value}\n");
  }

  Future<String> _getDocumentPath() async {
    return appFlowyApplicationDataDirectory().then((directory) {
      final path = directory.path.toString();
      return "Document: $path\n";
    });
  }
}

class FlowyVersionDescription extends CustomActionCell {
  FlowyVersionDescription({required this.popoverMutex});

  final PopoverMutex popoverMutex;

  @override
  Widget buildWithContext(BuildContext context) {
    return BlocProvider.value(
      value: getIt<VersionCheckerBloc>(),
      child: BlocBuilder<VersionCheckerBloc, VersionCheckerState>(
        builder: (context, state) {
          return Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            padding: const EdgeInsets.only(top: 4),
            child: HoverButton(
              leftIcon: getLeftIcon(
                context,
                isLoading: state.isLoading,
                isUpdateAvailable: state.isUpdateAvailable,
              ),
              itemHeight: 20,
              name: '${state.appName} ${state.currentVersion}',
              onTap: () {
                PopoverContainer.of(context).close();
                showUpdateDialog(context, state);
              },
            ),
          );
        },
      ),
    );
  }

  Widget? getLeftIcon(
    BuildContext context, {
    required bool isLoading,
    required bool isUpdateAvailable,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(right: 4),
        child: SizedBox(
          height: 12,
          width: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (isUpdateAvailable) {
      return FlowySvg(
        FlowySvgs.close_s,
        size: const Size.square(18),
        color: Theme.of(context).colorScheme.error,
      );
    } else {
      return FlowySvg(
        FlowySvgs.check_s,
        size: const Size.square(18),
        color: AFThemeExtension.of(context).success,
      );
    }
  }

  void showUpdateDialog(BuildContext context, VersionCheckerState state) {
    Builder(
      builder: (context) {
        // Workaround for following theme updates
        Theme.of(context).brightness;

        return FlowyDialog(
          title: FlowyText.semibold(
            state.isUpdateAvailable
                ? LocaleKeys.updateDialog_updateAvailable.tr(
                    args: [state.latestVersion ?? ''],
                  )
                : LocaleKeys.updateDialog_upToDate.tr(),
            fontSize: 20,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VSpace(8),
                  FlowyText(
                    state.isUpdateAvailable
                        ? LocaleKeys.updateDialog_updateAvailableContent.tr()
                        : LocaleKeys.updateDialog_upToDateContent.tr(),
                    fontSize: 12,
                    maxLines: 3,
                  ),
                  const VSpace(8),
                  Row(
                    children: [
                      if (state.isUpdateAvailable &&
                          state.downloadLink != null) ...[
                        FlowyTextButton(
                          LocaleKeys.updateDialog_downloadLabel.tr(),
                          fillColor: Theme.of(context).colorScheme.primary,
                          hoverColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          fontColor: Theme.of(context).colorScheme.onPrimary,
                          onPressed: () =>
                              afLaunchUrlString(state.downloadLink!),
                        ),
                        const HSpace(8),
                      ],
                      FlowyTextButton(
                        LocaleKeys.updateDialog_allReleaseNotes.tr(),
                        fillColor: Theme.of(context).colorScheme.primary,
                        hoverColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        fontColor: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () => afLaunchUrlString(_whatIsNewUrl),
                      ),
                    ],
                  ),
                  if (state.changelog?.trim() != null) ...[
                    const VSpace(12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: AFThemeExtension.of(context).lightGreyHover,
                      ),
                      child: AppFlowyEditor(
                        editorStyle: EditorStyle.desktop(
                          padding: const EdgeInsets.all(12),
                          textScaleFactor: 0.8,
                          textStyleConfiguration: TextStyleConfiguration(
                            text: Theme.of(context).textTheme.bodyLarge ??
                                const TextStyle(),
                          ),
                        ),
                        editable: false,
                        shrinkWrap: true,
                        editorState: EditorState(
                          document:
                              markdownToDocument(state.changelog?.trim() ?? ''),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ).show(context);
  }
}

enum BubbleAction { whatsNews, help, debug, shortcuts, markdown, github }

class BubbleActionWrapper extends ActionCell {
  BubbleActionWrapper(this.inner);

  final BubbleAction inner;

  @override
  Widget? leftIcon(Color iconColor) => inner.emoji;

  @override
  String get name => inner.name;
}

extension QuestionBubbleExtension on BubbleAction {
  String get name {
    switch (this) {
      case BubbleAction.whatsNews:
        return LocaleKeys.questionBubble_whatsNew.tr();
      case BubbleAction.help:
        return LocaleKeys.questionBubble_help.tr();
      case BubbleAction.debug:
        return LocaleKeys.questionBubble_debug_name.tr();
      case BubbleAction.shortcuts:
        return LocaleKeys.questionBubble_shortcuts.tr();
      case BubbleAction.markdown:
        return LocaleKeys.questionBubble_markdown.tr();
      case BubbleAction.github:
        return LocaleKeys.questionBubble_feedback.tr();
    }
  }

  Widget get emoji {
    switch (this) {
      case BubbleAction.whatsNews:
        return const FlowyText.regular('🆕');
      case BubbleAction.help:
        return const FlowyText.regular('👥');
      case BubbleAction.debug:
        return const FlowyText.regular('🐛');
      case BubbleAction.shortcuts:
        return const FlowyText.regular('📋');
      case BubbleAction.markdown:
        return const FlowyText.regular('✨');
      case BubbleAction.github:
        return const Padding(
          padding: EdgeInsets.all(.5),
          child: FlowySvg(FlowySvgs.archive_m, size: Size.square(14)),
        );
    }
  }
}
