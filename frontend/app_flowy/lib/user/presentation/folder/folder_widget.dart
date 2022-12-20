import 'dart:io';

import 'package:app_flowy/util/file_picker/file_picker_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../generated/locale_keys.g.dart';
import '../../../startup/startup.dart';
import '../../../workspace/application/settings/settings_location_cubit.dart';
import '../../../workspace/presentation/home/toast.dart';

enum _FolderPage {
  options,
  create,
  open,
}

class FolderWidget extends StatefulWidget {
  const FolderWidget({
    Key? key,
    required this.createFolderCallback,
  }) : super(key: key);

  final Future<void> Function() createFolderCallback;

  @override
  State<FolderWidget> createState() => _FolderWidgetState();
}

class _FolderWidgetState extends State<FolderWidget> {
  var page = _FolderPage.options;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: _mapIndexToWidget(context),
    );
  }

  Widget _mapIndexToWidget(BuildContext context) {
    switch (page) {
      case _FolderPage.options:
        return FolderOptionsWidget(
          onPressedCreate: () {
            setState(() => page = _FolderPage.create);
          },
          onPressedOpen: () {
            _openFolder();
          },
        );
      case _FolderPage.create:
        return CreateFolderWidget(
          onPressedBack: () {
            setState(() => page = _FolderPage.options);
          },
          onPressedCreate: widget.createFolderCallback,
        );
      case _FolderPage.open:
        return Container();
    }
  }

  Future<void> _openFolder() async {
    final directory = await getIt<FilePickerService>().getDirectoryPath();
    if (directory != null) {
      await getIt<SettingsLocationCubit>().setLocation(directory);
      await widget.createFolderCallback();
    }
  }
}

class FolderOptionsWidget extends StatelessWidget {
  const FolderOptionsWidget({
    Key? key,
    required this.onPressedCreate,
    required this.onPressedOpen,
  }) : super(key: key);

  final VoidCallback onPressedCreate;
  final VoidCallback onPressedOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Card(
          child: ListTile(
            title: FlowyText.medium(
              LocaleKeys.settings_files_createNewFolder.tr(),
            ),
            subtitle: FlowyText.regular(
              LocaleKeys.settings_files_createNewFolderDesc.tr(),
            ),
            trailing: _buildTextButton(
              context,
              LocaleKeys.settings_files_create.tr(),
              onPressedCreate,
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: FlowyText.medium(
              LocaleKeys.settings_files_openFolder.tr(),
            ),
            subtitle: FlowyText.regular(
              LocaleKeys.settings_files_openFolderDesc.tr(),
            ),
            trailing: _buildTextButton(
              context,
              LocaleKeys.settings_files_open.tr(),
              onPressedOpen,
            ),
          ),
        ),
      ],
    );
  }
}

class CreateFolderWidget extends StatefulWidget {
  const CreateFolderWidget({
    Key? key,
    required this.onPressedBack,
    required this.onPressedCreate,
  }) : super(key: key);

  final VoidCallback onPressedBack;
  final Future<void> Function() onPressedCreate;

  @override
  State<CreateFolderWidget> createState() => CreateFolderWidgetState();
}

@visibleForTesting
class CreateFolderWidgetState extends State<CreateFolderWidget> {
  var _folderName = 'appflowy';
  @visibleForTesting
  var directory = '';

  final _fToast = FToast();

  @override
  void initState() {
    super.initState();
    _fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onPressedBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
          ),
        ),
        Card(
          child: ListTile(
            title: FlowyText.medium(
              LocaleKeys.settings_files_location.tr(),
            ),
            subtitle: FlowyText.regular(
              LocaleKeys.settings_files_locationDesc.tr(),
            ),
            trailing: SizedBox(
              width: 100,
              height: 36,
              child: FlowyTextField(
                hintText: LocaleKeys.settings_files_folderHintText.tr(),
                onChanged: (name) {
                  _folderName = name;
                },
                onSubmitted: (name) {
                  setState(() {
                    _folderName = name;
                  });
                },
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: FlowyText.medium(LocaleKeys.settings_files_location.tr()),
            subtitle: FlowyText.regular(_path),
            trailing: _buildTextButton(
                context, LocaleKeys.settings_files_browser.tr(), () async {
              final dir = await getIt<FilePickerService>().getDirectoryPath();
              if (dir != null) {
                setState(() {
                  directory = dir;
                });
              }
            }),
          ),
        ),
        Card(
          child: _buildTextButton(context, 'create', () async {
            if (_path.isEmpty) {
              _showToast(LocaleKeys.settings_files_locationCannotBeEmpty.tr());
            } else {
              await getIt<SettingsLocationCubit>().setLocation(_path);
              await widget.onPressedCreate();
            }
          }),
        )
      ],
    );
  }

  String get _path {
    if (directory.isEmpty) return '';
    final String path;
    if (Platform.isMacOS) {
      path = directory.replaceAll('/Volumes/Macintosh HD', '');
    } else {
      path = directory;
    }
    return '$path/$_folderName';
  }

  void _showToast(String message) {
    _fToast.showToast(
      child: FlowyMessageToast(message: message),
      gravity: ToastGravity.CENTER,
    );
  }
}

Widget _buildTextButton(
    BuildContext context, String title, VoidCallback onPressed) {
  return SizedBox(
    width: 70,
    height: 36,
    child: RoundedTextButton(
      title: title,
      onPressed: onPressed,
    ),
  );
}
