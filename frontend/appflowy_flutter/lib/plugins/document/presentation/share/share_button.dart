library document_plugin;

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/plugins/document/application/share_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:clipboard/clipboard.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentShareButton extends StatelessWidget {
  final ViewPB view;
  DocumentShareButton({Key? key, required this.view})
      : super(key: ValueKey(view.hashCode));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DocShareBloc>(param1: view),
      child: BlocListener<DocShareBloc, DocShareState>(
        listener: (context, state) {
          state.map(
            initial: (_) {},
            loading: (_) {},
            finish: (state) {
              state.successOrFail.fold(
                _handleExportData,
                _handleExportError,
              );
            },
          );
        },
        child: BlocBuilder<DocShareBloc, DocShareState>(
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

  void _handleExportData(ExportDataPB exportData) {
    switch (exportData.exportType) {
      case ExportType.Link:
        break;
      case ExportType.Markdown:
        FlutterClipboard.copy(exportData.data)
            .then((value) => Log.info('copied to clipboard'));
        break;
      case ExportType.Text:
        break;
    }
  }

  void _handleExportError(FlowyError error) {}
}

class ShareActionList extends StatelessWidget {
  const ShareActionList({
    Key? key,
    required this.view,
  }) : super(key: key);

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    final docShareBloc = context.read<DocShareBloc>();
    return PopoverActionList<ShareActionWrapper>(
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 8),
      actions: ShareAction.values
          .map((action) => ShareActionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return RoundedTextButton(
          title: LocaleKeys.shareAction_buttonText.tr(),
          onPressed: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
        switch (action.inner) {
          case ShareAction.markdown:
            final exportPath = await FilePicker.platform.saveFile(
              dialogTitle: '',
              fileName: '${view.name}.md',
            );
            if (exportPath != null) {
              docShareBloc.add(DocShareEvent.shareMarkdown(exportPath));
              showMessageToast('Exported to: $exportPath');
            }
            break;
          // case ShareAction.copyLink:
          //   NavigatorAlertDialog(
          //     title: LocaleKeys.shareAction_workInProgress.tr(),
          //   ).show(context);
          //   break;
        }
        controller.close();
      },
    );
  }
}

enum ShareAction {
  markdown,
  // copyLink,
}

class ShareActionWrapper extends ActionCell {
  final ShareAction inner;

  ShareActionWrapper(this.inner);

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    switch (inner) {
      case ShareAction.markdown:
        return LocaleKeys.shareAction_markdown.tr();
      // case ShareAction.copyLink:
      //   return LocaleKeys.shareAction_copyLink.tr();
    }
  }
}
