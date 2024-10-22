import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra/theme_extension.dart';
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
    this.allowMultipleFiles = false,
  });

  final void Function(List<XFile> files) onInsertLocalFile;
  final void Function(String url) onInsertNetworkFile;
  final bool allowMultipleFiles;

  @override
  State<FileUploadMenu> createState() => _FileUploadMenuState();
}

class _FileUploadMenuState extends State<FileUploadMenu> {
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    // ClipRRect is used to clip the tab indicator, so the animation doesn't overflow the dialog
    return ClipRRect(
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              onTap: (value) => setState(() => currentTab = value),
              isScrollable: true,
              indicatorWeight: 3,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              overlayColor: WidgetStatePropertyAll(
                UniversalPlatform.isDesktop
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
              ),
              tabs: [
                _Tab(
                  title: LocaleKeys.document_plugins_file_uploadTab.tr(),
                  isSelected: currentTab == 0,
                ),
                _Tab(
                  title: LocaleKeys.document_plugins_file_networkTab.tr(),
                  isSelected: currentTab == 1,
                ),
              ],
            ),
            const Divider(height: 0),
            if (currentTab == 0) ...[
              _FileUploadLocal(
                allowMultipleFiles: widget.allowMultipleFiles,
                onFilesPicked: (files) {
                  if (files.isNotEmpty) {
                    widget.onInsertLocalFile(files);
                  }
                },
              ),
            ] else ...[
              _FileUploadNetwork(onSubmit: widget.onInsertNetworkFile),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.title, this.isSelected = false});

  final String title;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        bottom: 8.0,
        top: UniversalPlatform.isMobile ? 0 : 8.0,
      ),
      child: FlowyText.semibold(
        title,
        color: isSelected
            ? AFThemeExtension.of(context).strongText
            : Theme.of(context).hintColor,
      ),
    );
  }
}

class _FileUploadLocal extends StatefulWidget {
  const _FileUploadLocal({
    required this.onFilesPicked,
    this.allowMultipleFiles = false,
  });

  final void Function(List<XFile>) onFilesPicked;
  final bool allowMultipleFiles;

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
      padding: const EdgeInsets.all(16),
      child: DropTarget(
        onDragEntered: (_) => setState(() => isDragging = true),
        onDragExited: (_) => setState(() => isDragging = false),
        onDragDone: (details) => widget.onFilesPicked(details.files),
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
                hoverColor:
                    isDragging ? AFThemeExtension.of(context).tint9 : null,
              ),
              child: Container(
                height: 172,
                constraints: constraints,
                child: DottedBorder(
                  dashPattern: const [3, 3],
                  radius: const Radius.circular(8),
                  borderType: BorderType.RRect,
                  color: isDragging
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isDragging) ...[
                          FlowyText(
                            LocaleKeys.document_plugins_file_dropFileToUpload
                                .tr(),
                            fontSize: 16,
                            color: Theme.of(context).hintColor,
                          ),
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
    final result = await getIt<FilePickerService>().pickFiles(
      dialogTitle: '',
      allowMultiple: widget.allowMultipleFiles,
    );

    final List<XFile> files = result?.files.isNotEmpty ?? false
        ? result!.files.map((f) => f.xFile).toList()
        : const [];

    widget.onFilesPicked(files);
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
      padding: const EdgeInsets.all(16),
      constraints: constraints,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyTextField(
            hintText: LocaleKeys.document_plugins_file_networkHint.tr(),
            onChanged: (value) => inputText = value,
            onEditingComplete: submit,
          ),
          if (!isUrlValid) ...[
            const VSpace(4),
            FlowyText(
              LocaleKeys.document_plugins_file_networkUrlInvalid.tr(),
              color: Theme.of(context).colorScheme.error,
              maxLines: 3,
              textAlign: TextAlign.start,
            ),
          ],
          const VSpace(16),
          SizedBox(
            height: 32,
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
