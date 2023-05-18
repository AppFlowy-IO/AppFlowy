import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
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
              return ListTile(
                title: FlowyText.medium(
                  LocaleKeys.settings_files_defaultLocation.tr(),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Tooltip(
                  message: LocaleKeys.settings_files_doubleTapToCopy.tr(),
                  child: GestureDetector(
                    onDoubleTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: path,
                        ),
                      ).then((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: FlowyText(
                                LocaleKeys.settings_files_pathCopiedSnackbar
                                    .tr(),
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        }
                      });
                    },
                    child: FlowyText.regular(
                      path,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChangeStoragePathButton(
                      usingPath: path,
                    ),
                    const VSpace(5),
                    _RecoverDefaultStorageButton(
                      usingPath: path,
                    ),
                    const VSpace(5),
                    _OpenStorageButton(
                      usingPath: path,
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
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
    return FlowyTextButton(
      LocaleKeys.settings_files_change.tr(),
      tooltip: LocaleKeys.settings_files_changeLocationTooltips.tr(),
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
      tooltipText: LocaleKeys.settings_files_recoverLocationTooltips.tr(),
      icon: svgWidget(
        'common/open_folder',
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: () async {
        if (await canLaunchUrlString(usingPath)) {
          launchUrlString(usingPath);
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
