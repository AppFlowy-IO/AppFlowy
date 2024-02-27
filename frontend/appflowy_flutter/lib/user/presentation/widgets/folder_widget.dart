import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../generated/locale_keys.g.dart';
import '../../../startup/startup.dart';
import '../../../workspace/presentation/home/toast.dart';

enum _FolderPage {
  options,
  create,
  open,
}

class FolderWidget extends StatefulWidget {
  const FolderWidget({
    super.key,
    required this.createFolderCallback,
  });

  final Future<void> Function() createFolderCallback;

  @override
  State<FolderWidget> createState() => _FolderWidgetState();
}

class _FolderWidgetState extends State<FolderWidget> {
  var page = _FolderPage.options;

  @override
  Widget build(BuildContext context) {
    return _mapIndexToWidget(context);
  }

  Widget _mapIndexToWidget(BuildContext context) {
    switch (page) {
      case _FolderPage.options:
        return FolderOptionsWidget(
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
        return const SizedBox.shrink();
    }
  }

  Future<void> _openFolder() async {
    final path = await getIt<FilePickerService>().getDirectoryPath();
    if (path != null) {
      await getIt<ApplicationDataStorage>().setCustomPath(path);
      await widget.createFolderCallback();
      setState(() {});
    }
  }
}

class FolderOptionsWidget extends StatelessWidget {
  const FolderOptionsWidget({
    super.key,
    required this.onPressedOpen,
  });

  final VoidCallback onPressedOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getIt<ApplicationDataStorage>().getPath(),
      builder: (context, result) {
        final subtitle = result.hasData ? result.data! : '';
        return _FolderCard(
          icon: const FlowySvg(FlowySvgs.archive_m),
          title: LocaleKeys.settings_files_defineWhereYourDataIsStored.tr(),
          subtitle: subtitle,
          trailing: _buildTextButton(
            context,
            LocaleKeys.settings_files_set.tr(),
            onPressedOpen,
          ),
        );
      },
    );
  }
}

class CreateFolderWidget extends StatefulWidget {
  const CreateFolderWidget({
    super.key,
    required this.onPressedBack,
    required this.onPressedCreate,
  });

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
        _FolderCard(
          title: LocaleKeys.settings_files_location.tr(),
          subtitle: LocaleKeys.settings_files_locationDesc.tr(),
          trailing: SizedBox(
            width: 120,
            child: FlowyTextField(
              hintText: LocaleKeys.settings_files_folderHintText.tr(),
              onChanged: (name) => _folderName = name,
              onSubmitted: (name) => setState(
                () => _folderName = name,
              ),
            ),
          ),
        ),
        _FolderCard(
          title: LocaleKeys.settings_files_folderPath.tr(),
          subtitle: _path,
          trailing: _buildTextButton(
            context,
            LocaleKeys.settings_files_browser.tr(),
            () async {
              final dir = await getIt<FilePickerService>().getDirectoryPath();
              if (dir != null) {
                setState(() => directory = dir);
              }
            },
          ),
        ),
        const VSpace(4.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: _buildTextButton(
            context,
            LocaleKeys.settings_files_create.tr(),
            () async {
              if (_path.isEmpty) {
                _showToast(
                  LocaleKeys.settings_files_locationCannotBeEmpty.tr(),
                );
              } else {
                await getIt<ApplicationDataStorage>().setCustomPath(_path);
                await widget.onPressedCreate();
              }
            },
          ),
        ),
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
  BuildContext context,
  String title,
  VoidCallback onPressed,
) {
  return SecondaryTextButton(
    title,
    mode: TextButtonMode.small,
    onPressed: onPressed,
  );
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const cardSpacing = 16.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: cardSpacing,
          horizontal: cardSpacing,
        ),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: cardSpacing),
                child: icon!,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: FlowyText.regular(
                          title,
                          fontSize: FontSizes.s14,
                          fontFamily: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ).fontFamily,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tooltip(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        preferBelow: false,
                        richMessage: WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Container(
                            color: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: FlowyText(
                              LocaleKeys.settings_menu_customPathPrompt.tr(),
                              maxLines: null,
                            ),
                          ),
                        ),
                        child: const FlowyIconButton(
                          icon: Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const VSpace(4),
                  FlowyText.regular(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    fontSize: FontSizes.s12,
                    fontFamily: GoogleFonts.poppins(
                      fontWeight: FontWeight.w300,
                    ).fontFamily,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const HSpace(cardSpacing),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
