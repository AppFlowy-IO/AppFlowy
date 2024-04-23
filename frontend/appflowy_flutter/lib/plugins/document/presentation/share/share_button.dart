import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_share_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
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
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/foundation.dart';
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
          state.mapOrNull(
            finish: (state) {
              state.successOrFail.fold(
                (data) => _handleExportData(context, data),
                _handleExportError,
              );
            },
          );
        },
        child: BlocBuilder<DocumentShareBloc, DocumentShareState>(
          builder: (context, state) => ConstrainedBox(
            constraints: const BoxConstraints.expand(
              height: 30,
              width: 100,
            ),
            child: ShareActionList(view: view),
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
    final shareActions = [
      ShareAction.markdown,
      ShareAction.html,
      ShareAction.clipboard,
      if (kDebugMode) ShareAction.json,
    ];
    return PopoverActionList<ShareActionWrapper>(
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 8),
      actions:
          shareActions.map((action) => ShareActionWrapper(action)).toList(),
      buildChild: (controller) => Listener(
        onPointerDown: (_) => controller.show(),
        child: RoundedTextButton(
          title: LocaleKeys.shareAction_buttonText.tr(),
          onPressed: () {},
          textColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      onSelected: (action, controller) async {
        final exportPath = await _handleShareAction(action, docShareBloc);
        if (exportPath != null) {
          docShareBloc.add(
            DocumentShareEvent.share(
              _getDocumentShareType(action),
              exportPath,
            ),
          );
        }
        controller.close();
      },
    );
  }

  Future<String?> _handleShareAction(
    ShareActionWrapper action,
    DocumentShareBloc docShareBloc,
  ) async {
    switch (action.inner) {
      case ShareAction.markdown:
      case ShareAction.html:
      case ShareAction.json:
        return getIt<FilePickerService>().saveFile(
          dialogTitle: '',
          fileName: '${name.toFileName()}.${action.inner.ext}',
        );
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
    return null;
  }

  DocumentShareType _getDocumentShareType(ShareActionWrapper action) {
    switch (action.inner) {
      case ShareAction.markdown:
        return DocumentShareType.markdown;
      case ShareAction.html:
        return DocumentShareType.html;
      case ShareAction.json:
        return DocumentShareType.json;
      default:
        throw Exception('Unsupported share action');
    }
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
  json;

  String get ext {
    switch (this) {
      case ShareAction.markdown:
        return 'md';
      case ShareAction.html:
        return 'html';
      case ShareAction.json:
        return 'json';
      case ShareAction.clipboard:
        return '';
    }
  }
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
      case ShareAction.json:
        return 'Export JSON (ONLY FOR DEVELOPMENT)';
    }
  }
}
