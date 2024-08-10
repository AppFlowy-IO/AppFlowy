import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExportTab extends StatelessWidget {
  const ExportTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final view = context.read<ShareBloc>().view;

    if (view.layout == ViewLayoutPB.Document) {
      return _buildDocumentExportTab(context);
    }

    return _buildDatabaseExportTab(context);
  }

  Widget _buildDocumentExportTab(BuildContext context) {
    return Column(
      children: [
        const VSpace(10),
        _ExportButton(
          title: LocaleKeys.shareAction_html.tr(),
          svg: FlowySvgs.export_html_s,
          onTap: () => _exportHTML(context),
        ),
        const VSpace(10),
        _ExportButton(
          title: LocaleKeys.shareAction_markdown.tr(),
          svg: FlowySvgs.export_markdown_s,
          onTap: () => _exportMarkdown(context),
        ),
        const VSpace(10),
        _ExportButton(
          title: LocaleKeys.shareAction_clipboard.tr(),
          svg: FlowySvgs.duplicate_s,
          onTap: () => _exportToClipboard(context),
        ),
      ],
    );
  }

  Widget _buildDatabaseExportTab(BuildContext context) {
    return Column(
      children: [
        const VSpace(10),
        _ExportButton(
          title: LocaleKeys.shareAction_csv.tr(),
          svg: FlowySvgs.database_layout_m,
          onTap: () => _exportCSV(context),
        ),
      ],
    );
  }

  Future<void> _exportHTML(BuildContext context) async {
    final viewName = context.read<ShareBloc>().state.viewName;
    final exportPath = await getIt<FilePickerService>().saveFile(
      dialogTitle: '',
      fileName: '${viewName.toFileName()}.html',
    );
    if (context.mounted && exportPath != null) {
      context.read<ShareBloc>().add(
            ShareEvent.share(
              ShareType.html,
              exportPath,
            ),
          );
    }
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final viewName = context.read<ShareBloc>().state.viewName;
    final exportPath = await getIt<FilePickerService>().saveFile(
      dialogTitle: '',
      fileName: '${viewName.toFileName()}.md',
    );
    if (context.mounted && exportPath != null) {
      context.read<ShareBloc>().add(
            ShareEvent.share(
              ShareType.markdown,
              exportPath,
            ),
          );
    }
  }

  Future<void> _exportCSV(BuildContext context) async {
    final viewName = context.read<ShareBloc>().state.viewName;
    final exportPath = await getIt<FilePickerService>().saveFile(
      dialogTitle: '',
      fileName: '${viewName.toFileName()}.csv',
    );
    if (context.mounted && exportPath != null) {
      context.read<ShareBloc>().add(
            ShareEvent.share(
              ShareType.csv,
              exportPath,
            ),
          );
    }
  }

  Future<void> _exportToClipboard(BuildContext context) async {
    final documentExporter = DocumentExporter(context.read<ShareBloc>().view);
    final result = await documentExporter.export(DocumentExportType.markdown);
    result.fold(
      (markdown) {
        getIt<ClipboardService>().setData(
          ClipboardServiceData(plainText: markdown),
        );
        showToastNotification(
          context,
          message: LocaleKeys.grid_url_copiedNotification.tr(),
        );
      },
      (error) => showToastNotification(context, message: error.msg),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.title,
    required this.svg,
    required this.onTap,
  });

  final String title;
  final FlowySvgData svg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).isLightMode
        ? const Color(0x1E14171B)
        : Colors.white.withOpacity(0.1);
    final radius = BorderRadius.circular(10.0);
    return FlowyButton(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      iconPadding: 12,
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
        ),
        borderRadius: radius,
      ),
      radius: radius,
      text: FlowyText(
        title,
        lineHeight: 1.0,
      ),
      leftIcon: FlowySvg(svg),
      onTap: onTap,
    );
  }
}
