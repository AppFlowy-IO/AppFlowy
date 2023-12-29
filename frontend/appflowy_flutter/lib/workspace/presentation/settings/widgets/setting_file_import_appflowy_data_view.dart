import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/setting_file_importer_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ImportAppFlowyData extends StatefulWidget {
  const ImportAppFlowyData({super.key});

  @override
  State<ImportAppFlowyData> createState() => _ImportAppFlowyDataState();
}

class _ImportAppFlowyDataState extends State<ImportAppFlowyData> {
  final _fToast = FToast();
  @override
  void initState() {
    super.initState();
    _fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingFileImporterBloc(),
      child: BlocListener<SettingFileImporterBloc, SettingFileImportState>(
        listener: (context, state) {
          state.successOrFail.fold(
            () {},
            (either) {
              either.fold(
                (unit) {
                  _showToast(LocaleKeys.settings_menu_importSuccess.tr());
                },
                (err) {
                  _showToast(LocaleKeys.settings_menu_importFailed.tr());
                },
              );
            },
          );
        },
        child: BlocBuilder<SettingFileImporterBloc, SettingFileImportState>(
          builder: (context, state) {
            return Column(
              children: [
                const ImportAppFlowyDataButton(),
                const VSpace(6),
                IntrinsicHeight(
                  child: Opacity(
                    opacity: 0.6,
                    child: FlowyText.medium(
                      LocaleKeys.settings_menu_importAppFlowyDataDescription
                          .tr(),
                      maxLines: 13,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showToast(String message) {
    _fToast.showToast(
      child: FlowyMessageToast(message: message),
      gravity: ToastGravity.CENTER,
    );
  }
}

class ImportAppFlowyDataButton extends StatefulWidget {
  const ImportAppFlowyDataButton({super.key});

  @override
  State<ImportAppFlowyDataButton> createState() =>
      _ImportAppFlowyDataButtonState();
}

class _ImportAppFlowyDataButtonState extends State<ImportAppFlowyDataButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FlowyButton(
        text: FlowyText(LocaleKeys.settings_menu_importAppFlowyData.tr()),
        onTap: () async {
          final path = await getIt<FilePickerService>().getDirectoryPath();
          if (path == null) {
            return;
          }
          if (!mounted) {
            return;
          }

          context
              .read<SettingFileImporterBloc>()
              .add(SettingFileImportEvent.importAppFlowyDataFolder(path));
        },
      ),
    );
  }
}
