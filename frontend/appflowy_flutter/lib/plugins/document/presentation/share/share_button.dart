import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_share_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/share/share_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentShareButton extends StatelessWidget {
  const DocumentShareButton({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DocumentShareBloc>(param1: view),
      child: BlocListener<DocumentShareBloc, DocumentShareState>(
        listener: (context, state) {
          if (state.isLoading == false && state.exportResult != null) {
            state.exportResult!.fold(
              (data) => _handleExportData(context, data),
              _handleExportError,
            );
          }
        },
        child: BlocBuilder<DocumentShareBloc, DocumentShareState>(
          builder: (context, state) => SizedBox(
            height: 32.0,
            child: IntrinsicWidth(
              child: AppFlowyPopover(
                direction: PopoverDirection.bottomWithRightAligned,
                constraints: const BoxConstraints(
                  maxWidth: 422,
                ),
                margin: const EdgeInsets.all(16),
                offset: const Offset(0, 8),
                popupBuilder: (context) => const ShareMenu(),
                child: RoundedTextButton(
                  title: LocaleKeys.shareAction_buttonText.tr(),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  fontSize: 14.0,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleExportData(BuildContext context, ExportDataPB exportData) {
    switch (exportData.exportType) {
      case ExportType.Markdown:
        showSnackBarMessage(
          context,
          LocaleKeys.settings_files_exportFileSuccess.tr(),
        );
        break;
      case ExportType.Link:
      case ExportType.Text:
        break;
      case ExportType.HTML:
        showSnackBarMessage(
          context,
          LocaleKeys.settings_files_exportFileSuccess.tr(),
        );
        break;
    }
  }

  void _handleExportError(FlowyError error) {
    showMessageToast(error.msg);
  }
}

class ShareActionList extends StatefulWidget {
  const ShareActionList({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  State<ShareActionList> createState() => ShareActionListState();
}

@visibleForTesting
class ShareActionListState extends State<ShareActionList> {
  late String name;
  late final ViewListener viewListener = ViewListener(viewId: widget.view.id);

  @override
  void initState() {
    super.initState();
    listenOnViewUpdated();
  }

  @override
  void dispose() {
    viewListener.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docShareBloc = context.read<DocumentShareBloc>();
    return PopoverActionList<ShareActionWrapper>(
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 8),
      actions: ShareAction.values
          .map((action) => ShareActionWrapper(action))
          .toList(),
      buildChild: (controller) => Listener(
        onPointerDown: (_) => controller.show(),
        child: RoundedTextButton(
          title: LocaleKeys.shareAction_buttonText.tr(),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          onPressed: () {},
          fontSize: 14.0,
          textColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      onSelected: (action, controller) async {
        switch (action.inner) {
          case ShareAction.markdown:
            final exportPath = await getIt<FilePickerService>().saveFile(
              dialogTitle: '',
              // encode the file name in case it contains special characters
              fileName: '${name.toFileName()}.md',
            );
            if (exportPath != null) {
              docShareBloc.add(
                DocumentShareEvent.share(
                  DocumentShareType.markdown,
                  exportPath,
                ),
              );
            }
            break;
          case ShareAction.html:
            final exportPath = await getIt<FilePickerService>().saveFile(
              dialogTitle: '',
              fileName: '${name.toFileName()}.html',
            );
            if (exportPath != null) {
              docShareBloc.add(
                DocumentShareEvent.share(
                  DocumentShareType.html,
                  exportPath,
                ),
              );
            }
            break;
          case ShareAction.clipboard:
            final documentExporter = DocumentExporter(widget.view);
            final result =
                await documentExporter.export(DocumentExportType.markdown);
            result.fold(
              (markdown) => getIt<ClipboardService>()
                  .setData(ClipboardServiceData(plainText: markdown)),
              (error) => showMessageToast(error.msg),
            );
            break;
        }
        controller.close();
      },
    );
  }

  void listenOnViewUpdated() {
    name = widget.view.name;
    viewListener.start(
      onViewUpdated: (view) {
        name = view.name;
      },
    );
  }
}

enum ShareAction {
  markdown,
  html,
  clipboard,
}

class ShareActionWrapper extends ActionCell {
  ShareActionWrapper(this.inner);

  final ShareAction inner;

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    switch (inner) {
      case ShareAction.markdown:
        return LocaleKeys.shareAction_markdown.tr();
      case ShareAction.html:
        return LocaleKeys.shareAction_html.tr();
      case ShareAction.clipboard:
        return LocaleKeys.shareAction_clipboard.tr();
    }
  }
}
