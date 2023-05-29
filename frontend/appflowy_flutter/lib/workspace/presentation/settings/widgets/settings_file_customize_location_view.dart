import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/services.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../main.dart';
import '../../../../startup/launch_configuration.dart';
import '../../../../startup/startup.dart';
import '../../../../startup/tasks/prelude.dart';

class SettingsFileLocationCustomizer extends StatefulWidget {
  const SettingsFileLocationCustomizer({
    super.key,
    required this.cubit,
  });

  final SettingsLocationCubit cubit;

  @override
  State<SettingsFileLocationCustomizer> createState() =>
      SettingsFileLocationCustomizerState();
}

@visibleForTesting
class SettingsFileLocationCustomizerState
    extends State<SettingsFileLocationCustomizer> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsLocationCubit>.value(
      value: widget.cubit,
      child: BlocBuilder<SettingsLocationCubit, SettingsLocation>(
        builder: (context, state) {
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
                      text: state.path,
                    ),
                  ).then((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: FlowyText(
                            LocaleKeys.settings_files_pathCopiedSnackbar.tr(),
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }
                  });
                },
                child: FlowyText.regular(
                  state.path ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: LocaleKeys.settings_files_restoreLocation.tr(),
                  child: FlowyIconButton(
                    height: 40,
                    width: 40,
                    icon: const Icon(Icons.restore_outlined),
                    hoverColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    onPressed: () async {
                      final result = await appFlowyDocumentDirectory();
                      await _setCustomLocation(result.path);
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
                ),
                const SizedBox(
                  width: 5,
                ),
                Tooltip(
                  message: LocaleKeys.settings_files_customizeLocation.tr(),
                  child: FlowyIconButton(
                    height: 40,
                    width: 40,
                    icon: const Icon(Icons.folder_open_outlined),
                    hoverColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    onPressed: () async {
                      final result =
                          await getIt<FilePickerService>().getDirectoryPath();
                      if (result != null) {
                        await _setCustomLocation(result);
                        await reloadApp();
                      }
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _setCustomLocation(String? path) async {
    // Using default location if path equals null.
    final location = path ?? (await appFlowyDocumentDirectory()).path;
    if (mounted) {
      widget.cubit.setLocation(location);
    }

    // The location could not save into the KV db, because the db initialize is later than the rust sdk initialize.
    /*
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      context
          .read<AppearanceSettingsCubit>()
          .setKeyValue(AppearanceKeys.defaultLocation, location);
    }
    */
  }

  Future<void> reloadApp() async {
    await FlowyRunner.run(
      FlowyApp(),
      config: const LaunchConfiguration(
        autoRegistrationSupported: true,
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
    return;
  }
}
