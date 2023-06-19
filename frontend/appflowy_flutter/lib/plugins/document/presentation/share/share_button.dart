import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/plugins/document/application/share_bloc.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
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
      create: (context) => getIt<DocShareBloc>(param1: view),
      child: BlocListener<DocShareBloc, DocShareState>(
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
            final exportPath = await getIt<FilePickerService>().saveFile(
              dialogTitle: '',
              fileName: '$name.md',
            );
            if (exportPath != null) {
              docShareBloc.add(DocShareEvent.shareMarkdown(exportPath));
            }
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
    }
  }
}
