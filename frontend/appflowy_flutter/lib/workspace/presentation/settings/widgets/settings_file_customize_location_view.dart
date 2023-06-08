import 'dart:io';

import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../startup/launch_configuration.dart';
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
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // display file paths.
                  Flexible(
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
                  ),

                  // display the icons
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ChangeStoragePathButton(
                          usingPath: path,
                        ),
                        const HSpace(10),
                        _OpenStorageButton(
                          usingPath: path,
                        ),
                        _RecoverDefaultStorageButton(
                          usingPath: path,
                        ),
                      ],
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
    return Tooltip(
      message: LocaleKeys.settings_files_changeLocationTooltips.tr(),
      child: SecondaryTextButton(
        LocaleKeys.settings_files_change.tr(),
        mode: SecondaryTextButtonMode.small,
        onPressed: () async {
          // pick the new directory and reload app
          final path = await getIt<FilePickerService>().getDirectoryPath();
          if (path == null || !mounted || widget.usingPath == path) {
            return;
          }
          await context.read<SettingsLocationCubit>().setPath(path);
          await FlowyRunner.run(
            FlowyApp(),
            config: const LaunchConfiguration(
              autoRegistrationSupported: true,
            ),
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
      tooltipText: LocaleKeys.settings_files_openLocationTooltips.tr(),
      icon: svgWidget(
        'common/open_folder',
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
      icon: svgWidget(
        'common/recover',
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: () async {
        // reset to the default directory and reload app
        final directory = await appFlowyDocumentDirectory();
        final path = directory.path;
        if (!mounted || widget.usingPath == path) {
          return;
        }
        await context.read<SettingsLocationCubit>().setPath(path);
        await FlowyRunner.run(
          FlowyApp(),
          config: const LaunchConfiguration(
            autoRegistrationSupported: true,
          ),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
