import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/shared/permission/permission_checker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_platform/universal_platform.dart';

class MobileFileUploadMenu extends StatefulWidget {
  const MobileFileUploadMenu({
    super.key,
    required this.onInsertLocalFile,
    required this.onInsertNetworkFile,
    this.allowMultipleFiles = false,
  });

  final void Function(List<XFile> files) onInsertLocalFile;
  final void Function(String url) onInsertNetworkFile;
  final bool allowMultipleFiles;

  @override
  State<MobileFileUploadMenu> createState() => _MobileFileUploadMenuState();
}

class _MobileFileUploadMenuState extends State<MobileFileUploadMenu> {
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
              indicatorWeight: 3,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: FlowyButton(
              radius: Corners.s8Border,
              backgroundColor: Theme.of(context).colorScheme.primary,
              hoverColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.9),
              margin: const EdgeInsets.all(5),
              text: FlowyText(
                LocaleKeys.document_plugins_file_uploadMobileGallery.tr(),
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onTap: () => _uploadFileFromGallery(context),
            ),
          ),
          const VSpace(16),
          SizedBox(
            height: 36,
            child: FlowyButton(
              radius: Corners.s8Border,
              backgroundColor: Theme.of(context).colorScheme.primary,
              hoverColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.9),
              margin: const EdgeInsets.all(5),
              text: FlowyText(
                LocaleKeys.document_plugins_file_uploadMobile.tr(),
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onTap: () => _uploadFile(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFileFromGallery(BuildContext context) async {
    final photoPermission =
        await PermissionChecker.checkPhotoPermission(context);
    if (!photoPermission) {
      Log.error('Has no permission to access the photo library');
      return;
    }
    // on mobile, the users can pick a image file from camera or image library
    final files = await ImagePicker().pickMultiImage();

    widget.onFilesPicked(files);
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
            height: 36,
            child: FlowyButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              hoverColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.9),
              radius: Corners.s8Border,
              margin: const EdgeInsets.all(5),
              text: FlowyText(
                LocaleKeys.grid_media_embedLink.tr(),
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
