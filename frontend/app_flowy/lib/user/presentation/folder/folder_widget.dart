import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';

enum _FolderPage {
  options,
  create,
  open,
}

class FolderWidget extends StatefulWidget {
  const FolderWidget({Key? key}) : super(key: key);

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
            setState(() => page = _FolderPage.open);
          },
        );
      case _FolderPage.create:
        return OpenFolderWidget(
          onPressedBack: () {
            setState(() => page = _FolderPage.options);
          },
        );
      case _FolderPage.open:
        break;
      default:
    }
    return Container();
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
            title: const FlowyText.medium('Create a new folder'),
            subtitle: const FlowyText.regular('Create a new folder ...'),
            trailing: SizedBox(
              width: 60,
              height: 30,
              child: RoundedTextButton(
                title: 'Create',
                onPressed: onPressedCreate,
              ),
            ),
            // isThreeLine: true,
          ),
        ),
        Card(
          child: ListTile(
            title: const FlowyText.medium('Open folder'),
            subtitle: const FlowyText.regular('Open folder ...'),
            trailing: SizedBox(
              width: 60,
              height: 30,
              child: RoundedTextButton(
                title: 'Open',
                onPressed: onPressedOpen,
              ),
            ),
            // isThreeLine: true,
          ),
        ),
      ],
    );
  }
}

class OpenFolderWidget extends StatefulWidget {
  const OpenFolderWidget({
    Key? key,
    required this.onPressedBack,
  }) : super(key: key);

  final VoidCallback onPressedBack;

  @override
  State<OpenFolderWidget> createState() => _OpenFolderWidgetState();
}

class _OpenFolderWidgetState extends State<OpenFolderWidget> {
  var _folderName = '';
  var _path = '';

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
            title: const FlowyText.medium('Folder name'),
            subtitle: const FlowyText.regular('Open folder ...'),
            trailing: SizedBox(
              width: 100,
              height: 36,
              child: FlowyTextField(
                hintText: 'folder name',
                onChanged: (name) {
                  _folderName = name;
                },
              ),
            ),
            // isThreeLine: true,
          ),
        ),
        Card(
          child: ListTile(
            title: const FlowyText.medium('Location'),
            subtitle: FlowyText.regular(_path),
            trailing: _buildTextButton(context, 'Browse', () async {
              final directory = await FilePicker.platform.getDirectoryPath();
              if (directory != null) {
                setState(() {
                  if (Platform.isMacOS) {
                    _path = directory.replaceAll('/Volumes/Macintosh HD', '');
                  } else {
                    _path = directory;
                  }
                  _path += '/$_folderName';
                });
              }
            }),
          ),
        ),
        Card(
          child: _buildTextButton(context, 'create', () {}),
        )
      ],
    );
  }
}

Widget _buildTextButton(
    BuildContext context, String title, VoidCallback onPressed) {
  return SizedBox(
    width: 60,
    height: 36,
    child: RoundedTextButton(
      title: title,
      onPressed: onPressed,
    ),
  );
}
