import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/startup/tasks/prelude.dart';
import 'package:app_flowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:app_flowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsFileSystemView extends StatefulWidget {
  const SettingsFileSystemView({
    super.key,
  });

  @override
  State<SettingsFileSystemView> createState() => _SettingsFileSystemViewState();
}

class _SettingsFileSystemViewState extends State<SettingsFileSystemView> {
  final _locationCubit = SettingsLocationCubit()..fetchLocation();
  final _fToast = FToast();

  @override
  void initState() {
    super.initState();

    _fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildLocationCustomizer();
        }
        return Container();
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: 1,
    );
  }

  // Customize Default Location
  Widget _buildLocationCustomizer() {
    return BlocProvider<SettingsLocationCubit>.value(
      value: _locationCubit,
      child: BlocBuilder<SettingsLocationCubit, SettingsLocation>(
          builder: (context, state) {
        return ListTile(
          title: FlowyText.regular(
            LocaleKeys.settings_files_defaultLocation.tr(),
            fontSize: 16.0,
          ),
          subtitle: Tooltip(
            message: LocaleKeys.settings_files_doubleTapToCopy.tr(),
            child: GestureDetector(
              onDoubleTap: () {
                Clipboard.setData(ClipboardData(
                  text: state.path,
                ));
              },
              child: FlowyText.regular(
                state.path ?? '',
                fontSize: 12.0,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: LocaleKeys.settings_files_restoreLocation.tr(),
                child: FlowyIconButton(
                  icon: const Icon(Icons.restore_outlined),
                  onPressed: () async {
                    final result = await appFlowyDocumentDirectory();
                    await _setCustomLocation(result.path);
                    setState(() {});
                  },
                ),
              ),
              Tooltip(
                message: LocaleKeys.settings_files_customizeLocation.tr(),
                child: FlowyIconButton(
                  icon: const Icon(Icons.folder_open_outlined),
                  onPressed: () async {
                    final result = await FilePicker.platform.getDirectoryPath();
                    await _setCustomLocation(result);
                    _showToast(LocaleKeys.settings_files_restartApp.tr());
                  },
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  Future<void> _setCustomLocation(String? path) async {
    // Using default location if path equals null.
    final location = path ?? (await appFlowyDocumentDirectory()).path;
    if (mounted) {
      _locationCubit.setLocation(location);
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

  void _showToast(String message) {
    _fToast.showToast(
      child: FlowyMessageToast(message: message),
      gravity: ToastGravity.CENTER,
    );
  }
}
