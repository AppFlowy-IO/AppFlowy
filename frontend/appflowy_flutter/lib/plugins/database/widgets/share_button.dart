import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/share_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DatabaseShareButton extends StatelessWidget {
  const DatabaseShareButton({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatabaseShareBloc(view: view),
      child: BlocListener<DatabaseShareBloc, DatabaseShareState>(
        listener: (context, state) {
          state.mapOrNull(
            finish: (state) {
              state.successOrFail.fold(
                (data) => _handleExportData(context),
                _handleExportError,
              );
            },
          );
        },
        child: BlocBuilder<DatabaseShareBloc, DatabaseShareState>(
          builder: (context, state) => ConstrainedBox(
            constraints: const BoxConstraints.expand(
              height: 30,
              width: 100,
            ),
            child: DatabaseShareActionList(view: view),
          ),
        ),
      ),
    );
  }

  void _handleExportData(BuildContext context) {
    showSnackBarMessage(
      context,
      LocaleKeys.settings_files_exportFileSuccess.tr(),
    );
  }

  void _handleExportError(FlowyError error) {
    showMessageToast(error.msg);
  }
}

class DatabaseShareActionList extends StatefulWidget {
  const DatabaseShareActionList({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  State<DatabaseShareActionList> createState() =>
      DatabaseShareActionListState();
}

@visibleForTesting
class DatabaseShareActionListState extends State<DatabaseShareActionList> {
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
    final databaseShareBloc = context.read<DatabaseShareBloc>();
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
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () {},
        ),
      ),
      onSelected: (action, controller) async {
        switch (action.inner) {
          case ShareAction.csv:
            final exportPath = await getIt<FilePickerService>().saveFile(
              dialogTitle: '',
              fileName: '${name.toFileName()}.csv',
            );
            if (exportPath != null) {
              databaseShareBloc.add(DatabaseShareEvent.shareCSV(exportPath));
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
  csv,
}

class ShareActionWrapper extends ActionCell {
  ShareActionWrapper(this.inner);

  final ShareAction inner;

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    switch (inner) {
      case ShareAction.csv:
        return LocaleKeys.shareAction_csv.tr();
    }
  }
}
