import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

class FileUploadMenu extends StatefulWidget {
  const FileUploadMenu({
    super.key,
    required this.onInsertLocalFile,
    required this.onInsertNetworkFile,
  });

  final void Function(XFile file) onInsertLocalFile;
  final void Function(String url) onInsertNetworkFile;

  @override
  State<FileUploadMenu> createState() => _FileUploadMenuState();
}

class _FileUploadMenuState extends State<FileUploadMenu> {
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            onTap: (value) => setState(() => currentTab = value),
            isScrollable: true,
            padding: EdgeInsets.zero,
            overlayColor: WidgetStatePropertyAll(
              UniversalPlatform.isDesktop
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.transparent,
            ),
            tabs: [
              _Tab(
                title: LocaleKeys.document_plugins_file_uploadTab.tr(),
              ),
              _Tab(
                title: LocaleKeys.document_plugins_file_networkTab.tr(),
              ),
            ],
          ),
          const Divider(height: 4),
          if (currentTab == 0) ...[
            _FileUploadLocal(
              onFilePicked: (file) {
                if (file != null) {
                  widget.onInsertLocalFile(file);
                }
              },
            ),
          ] else ...[
            _FileUploadNetwork(onSubmit: widget.onInsertNetworkFile),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        bottom: 8.0,
        top: UniversalPlatform.isMobile ? 0 : 8.0,
      ),
      child: FlowyText(title),
    );
  }
}

class _FileUploadLocal extends StatefulWidget {
  const _FileUploadLocal({required this.onFilePicked});

  final void Function(XFile?) onFilePicked;

  @override
  State<_FileUploadLocal> createState() => _FileUploadLocalState();
}

class _FileUploadLocalState extends State<_FileUploadLocal> {
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    final constraints =
        UniversalPlatform.isMobile ? const BoxConstraints(minHeight: 92) : null;

    if (UniversalPlatform.isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: 32,
          width: 300,
          child: FlowyButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
            showDefaultBoxDecorationOnMobile: true,
            margin: const EdgeInsets.all(5),
            text: FlowyText(
              LocaleKeys.document_plugins_file_uploadMobile.tr(),
              textAlign: TextAlign.center,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onTap: () => _uploadFile(context),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: DropTarget(
        onDragEntered: (_) => setState(() => isDragging = true),
        onDragExited: (_) => setState(() => isDragging = false),
        onDragDone: (details) => widget.onFilePicked(details.files.first),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _uploadFile(context),
            child: FlowyHover(
              resetHoverOnRebuild: false,
              isSelected: () => isDragging,
              style: HoverStyle(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                constraints: constraints,
                child: DottedBorder(
                  dashPattern: const [3, 3],
                  radius: const Radius.circular(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 32,
                  ),
                  borderType: BorderType.RRect,
                  color: isDragging
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isDragging) ...[
                          const VSpace(13.5),
                          FlowyText(
                            LocaleKeys.document_plugins_file_dropFileToUpload
                                .tr(),
                            fontSize: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const VSpace(13.5),
                        ] else ...[
                          FlowyText(
                            LocaleKeys.document_plugins_file_fileUploadHint
                                .tr(),
                            fontSize: 16,
                            maxLines: 2,
                            lineHeight: 1.5,
                            textAlign: TextAlign.center,
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadFile(BuildContext context) async {
    final result = await getIt<FilePickerService>().pickFiles(dialogTitle: '');
    final file =
        result?.files.isNotEmpty ?? false ? result?.files.first.xFile : null;
    widget.onFilePicked(file);
  }
}

class _FileUploadNetwork extends StatefulWidget {
  const _FileUploadNetwork({required this.onSubmit});

  final void Function(String url) onSubmit;

  @override
  State<_FileUploadNetwork> createState() => _FileUploadNetworkState();
}

class _FileUploadNetworkState extends State<_FileUploadNetwork> {
  bool isUrlValid = true;
  String inputText = '';

  @override
  Widget build(BuildContext context) {
    final constraints =
        UniversalPlatform.isMobile ? const BoxConstraints(minHeight: 92) : null;

    return Container(
      padding: const EdgeInsets.all(8),
      constraints: constraints,
      alignment: Alignment.center,
      child: Column(
        children: [
          const VSpace(12),
          FlowyTextField(
            hintText: LocaleKeys.document_plugins_file_networkHint.tr(),
            onChanged: (value) => inputText = value,
            onEditingComplete: submit,
          ),
          if (!isUrlValid) ...[
            const VSpace(8),
            FlowyText(
              LocaleKeys.document_plugins_file_networkUrlInvalid.tr(),
              color: Theme.of(context).colorScheme.error,
            ),
          ],
          const VSpace(20),
          SizedBox(
            height: 32,
            width: 300,
            child: FlowyButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              hoverColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.9),
              showDefaultBoxDecorationOnMobile: true,
              margin: const EdgeInsets.all(5),
              text: FlowyText(
                LocaleKeys.document_plugins_file_networkAction.tr(),
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onTap: submit,
            ),
          ),
          const VSpace(8),
        ],
      ),
    );
  }

  void submit() {
    if (checkUrlValidity(inputText)) {
      return widget.onSubmit(inputText);
    }

    setState(() => isUrlValid = false);
  }

  bool checkUrlValidity(String url) => hrefRegex.hasMatch(url);
}
