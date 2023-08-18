
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/import/import_type.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

typedef ImportFromNotionCallback = Future<void> Function(
  ImportFromNotionType type,
  String? path,
);

class ImportFromNotionWidget extends StatelessWidget {
  ImportFromNotionWidget({
    super.key,
    required this.callback,
  });

  final PopoverController popoverController = PopoverController();
  final ImportFromNotionCallback callback;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      popupBuilder: (BuildContext context) {
        return SelectNotionImportTypeWidget(
          popoverController: popoverController,
          callback: callback,
        );
      },
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(200, 200)),
      direction: PopoverDirection.bottomWithCenterAligned,
      margin: EdgeInsets.zero,
      triggerActions: PopoverTriggerFlags.none,
      child: FlowyButton(
        leftIcon: FlowySvg(
          const FlowySvgData('notion_logo'),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        leftIconSize: const Size.square(20),
        text: FlowyText.medium(
          LocaleKeys.importPanel_importFromNotionMarkdownZip.tr(),
          fontSize: 15,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () async {
          popoverController.show();
        },
      ),
    );
  }
}

class SelectNotionImportTypeWidget extends StatelessWidget {
  const SelectNotionImportTypeWidget({
    super.key,
    required this.popoverController,
    required this.callback,
  });

  final PopoverController popoverController;
  final ImportFromNotionCallback callback;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ImportFromNotionType.values
            .map(
              (type) => Card(
                child: FlowyButton(
                  leftIconSize: const Size.square(20),
                  text: FlowyText.medium(
                    type.toString(),
                    fontSize: 15,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    popoverController.close();
                    await FlowyOverlay.show(
                      context: context,
                      builder: (context) => NotionImportTips(
                        type: type,
                        callback: callback,
                      ),
                    );
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class NotionImportTips extends StatelessWidget {
  const NotionImportTips({
    super.key,
    required this.type,
    required this.callback,
  });

  final ImportFromNotionType type;
  final ImportFromNotionCallback callback;

  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: FlowyText.semibold(
        'Import Notion ${type.toString()}',
        fontSize: 20,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      constraints: BoxConstraints.loose(const Size(300, 200)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 20.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type.tooltips),
            Center(
              child: FlowyButton(
                text: FlowyText.medium(
                  LocaleKeys.importPanel_uploadZipFile.tr(),
                  fontSize: 15,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                onTap: () async {
                  final path = await showFilePicker(type);
                  await callback(type, path);
                  if (context.mounted) {
                    FlowyOverlay.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> showFilePicker(
    ImportFromNotionType importFromNotionType,
  ) async {
    final result = await getIt<FilePickerService>().pickFiles(
      type: FileType.custom,
      allowMultiple: importFromNotionType.allowMultiSelect,
      allowedExtensions: importFromNotionType.allowedExtensions,
    );
    return result?.files.firstOrNull?.path;
  }
}
