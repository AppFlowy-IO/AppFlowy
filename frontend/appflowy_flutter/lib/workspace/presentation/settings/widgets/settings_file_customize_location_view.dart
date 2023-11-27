import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../startup/startup.dart';
import '../../../../startup/tasks/prelude.dart';

class SettingsFileLocationCustomizer extends StatefulWidget {
  const SettingsFileLocationCustomizer({
    super.key,
  });

  @override
  State<SettingsFileLocationCustomizer> createState() =>
      SettingsFileLocationCustomizerState();
}

@visibleForTesting
class SettingsFileLocationCustomizerState
    extends State<SettingsFileLocationCustomizer> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsLocationCubit>(
      create: (_) => SettingsLocationCubit(),
      child: BlocBuilder<SettingsLocationCubit, SettingsLocationState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(
              child: CircularProgressIndicator(),
            ),
            didReceivedPath: (path) {
              return Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // display file paths.
                      _path(path),

                      // display the icons
                      _buttons(path),
                    ],
                  ),
                  const VSpace(10),
                  IntrinsicHeight(
                    child: Opacity(
                      opacity: 0.6,
                      child: FlowyText.medium(
                        LocaleKeys.settings_menu_customPathPrompt.tr(),
                        maxLines: 13,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _path(String path) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText.medium(
            LocaleKeys.settings_files_defaultLocation.tr(),
            fontSize: 13,
            overflow: TextOverflow.visible,
          ).padding(horizontal: 5),
          const VSpace(5),
          _CopyableText(
            usingPath: path,
          ),
        ],
      ),
    );
  }

  Widget _buttons(String path) {
    final List<Widget> children = [];
    children.addAll([
      Flexible(
        child: _ChangeStoragePathButton(
          usingPath: path,
        ),
      ),
      const HSpace(10),
    ]);

    children.add(
      _OpenStorageButton(
        usingPath: path,
      ),
    );

    children.add(
      _RecoverDefaultStorageButton(
        usingPath: path,
      ),
    );

    return Flexible(
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: children),
    );
  }
}

class _CopyableText extends StatelessWidget {
  const _CopyableText({
    required this.usingPath,
  });

  final String usingPath;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      builder: (_, onHover) {
        return GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: usingPath));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: FlowyText(
                  LocaleKeys.settings_files_pathCopiedSnackbar.tr(),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          },
          child: Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FlowyText.regular(
                    usingPath,
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onHover) ...[
                  const HSpace(5),
                  FlowyText.regular(
                    LocaleKeys.settings_files_copy.tr(),
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChangeStoragePathButton extends StatefulWidget {
  const _ChangeStoragePathButton({
    required this.usingPath,
  });

  final String usingPath;

  @override
  State<_ChangeStoragePathButton> createState() =>
      _ChangeStoragePathButtonState();
}

class _ChangeStoragePathButtonState extends State<_ChangeStoragePathButton> {
  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.settings_files_changeLocationTooltips.tr(),
      child: SecondaryTextButton(
        LocaleKeys.settings_files_change.tr(),
        mode: TextButtonMode.small,
        onPressed: () async {
          // pick the new directory and reload app
          final path = await getIt<FilePickerService>().getDirectoryPath();
          if (path == null || widget.usingPath == path) {
            return;
          }
          if (!mounted) {
            return;
          }
          await context.read<SettingsLocationCubit>().setCustomPath(path);
          await FlowyRunner.run(
            FlowyApp(),
            FlowyRunner.currentMode,
            isAnon: true,
          );
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}

class _OpenStorageButton extends StatelessWidget {
  const _OpenStorageButton({
    required this.usingPath,
  });

  final String usingPath;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      hoverColor: Theme.of(context).colorScheme.secondaryContainer,
      tooltipText: LocaleKeys.settings_files_openCurrentDataFolder.tr(),
      icon: FlowySvg(
        FlowySvgs.open_folder_lg,
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: () async {
        final uri = Directory(usingPath).uri;
        if (await canLaunchUrl(uri)) {
          launchUrl(uri);
        }
      },
    );
  }
}

class _RecoverDefaultStorageButton extends StatefulWidget {
  const _RecoverDefaultStorageButton({
    required this.usingPath,
  });

  final String usingPath;

  @override
  State<_RecoverDefaultStorageButton> createState() =>
      _RecoverDefaultStorageButtonState();
}

class _RecoverDefaultStorageButtonState
    extends State<_RecoverDefaultStorageButton> {
  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      hoverColor: Theme.of(context).colorScheme.secondaryContainer,
      tooltipText: LocaleKeys.settings_files_recoverLocationTooltips.tr(),
      icon: const FlowySvg(
        FlowySvgs.restore_s,
        size: Size.square(24),
      ),
      onPressed: () async {
        // reset to the default directory and reload app
        final directory = await appFlowyApplicationDataDirectory();
        final path = directory.path;
        if (widget.usingPath == path) {
          return;
        }
        if (!mounted) {
          return;
        }
        await context
            .read<SettingsLocationCubit>()
            .resetDataStoragePathToApplicationDefault();
        await FlowyRunner.run(
          FlowyApp(),
          FlowyRunner.currentMode,
          isAnon: true,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
