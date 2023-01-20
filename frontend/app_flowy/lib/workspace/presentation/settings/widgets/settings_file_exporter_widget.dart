import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/util/file_picker/file_picker_service.dart';
import 'package:app_flowy/workspace/application/settings/settings_file_exporter_cubit.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../generated/locale_keys.g.dart';

class FileExporterWidget extends StatefulWidget {
  const FileExporterWidget({Key? key}) : super(key: key);

  @override
  State<FileExporterWidget> createState() => _FileExporterWidgetState();
}

class _FileExporterWidgetState extends State<FileExporterWidget> {
  // Map<String, List<String>> _selectedPages = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.medium(
          LocaleKeys.settings_files_selectFiles.tr(),
          fontSize: 16.0,
        ),
        const VSpace(8),
        Expanded(child: _buildFileSelector(context)),
        const VSpace(8),
        _buildButtons(context)
      ],
    );
  }

  Row _buildButtons(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        FlowyTextButton(
          LocaleKeys.button_Cancel.tr(),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        const HSpace(8),
        FlowyTextButton(
          LocaleKeys.button_OK.tr(),
          onPressed: () async {
            // TODO: Export Data
            await getIt<FilePickerService>()
                .getDirectoryPath()
                .then((exportPath) {
              Navigator.of(context).pop();
            });
          },
        ),
      ],
    );
  }

  FutureBuilder<dartz.Either<WorkspaceSettingPB, FlowyError>>
      _buildFileSelector(BuildContext context) {
    return FutureBuilder<dartz.Either<WorkspaceSettingPB, FlowyError>>(
      future: FolderEventReadCurrentWorkspace().send(),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final workspaces = snapshot.data?.getLeftOrNull<WorkspaceSettingPB>();
          if (workspaces != null) {
            final apps = workspaces.workspace.apps.items;
            return BlocProvider<SettingsFileExporterCubit>(
              create: (_) => SettingsFileExporterCubit(apps: apps),
              child: const _ExpandedList(),
            );
          }
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

class _ExpandedList extends StatefulWidget {
  const _ExpandedList({
    Key? key,
    // required this.apps,
    // required this.onChanged,
  }) : super(key: key);

  // final List<AppPB> apps;
  // final void Function(Map<String, List<String>> selectedPages) onChanged;

  @override
  State<_ExpandedList> createState() => _ExpandedListState();
}

class _ExpandedListState extends State<_ExpandedList> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsFileExporterCubit, SettingsFileExportState>(
      builder: (context, state) {
        return Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Column(
              children: _buildChildren(context),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final apps = context.read<SettingsFileExporterCubit>().state.apps;
    List<Widget> children = [];
    for (var i = 0; i < apps.length; i++) {
      children.add(_buildExpandedItem(context, i));
    }
    return children;
  }

  Widget _buildExpandedItem(BuildContext context, int index) {
    final state = context.read<SettingsFileExporterCubit>().state;
    final apps = state.apps;
    final expanded = state.expanded;
    final selectedItems = state.selectedItems;
    final isExpaned = expanded[index] == true;
    List<Widget> expandedChildren = [];
    if (isExpaned) {
      for (var i = 0; i < selectedItems[index].length; i++) {
        final name = apps[index].belongings.items[i].name;
        final checkbox = CheckboxListTile(
          value: selectedItems[index][i],
          onChanged: (value) {
            // update selected item
            context
                .read<SettingsFileExporterCubit>()
                .selectOrDeselectItem(index, i);
          },
          title: FlowyText.regular('  $name'),
        );
        expandedChildren.add(checkbox);
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context
              .read<SettingsFileExporterCubit>()
              .expandOrUnexpandApp(index),
          child: ListTile(
            title: FlowyText.medium(apps[index].name),
            trailing: Icon(
              isExpaned
                  ? Icons.arrow_drop_down_rounded
                  : Icons.arrow_drop_up_rounded,
            ),
          ),
        ),
        ...expandedChildren,
      ],
    );
  }
}

extension AppFlowy on dartz.Either {
  T? getLeftOrNull<T>() {
    if (isLeft()) {
      final result = fold<T?>((l) => l, (r) => null);
      return result;
    }

    return null;
  }
}
