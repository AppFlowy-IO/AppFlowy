import 'dart:io';

import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/settings/settings_file_exporter_cubit.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart' hide WidgetBuilder;
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:tuple/tuple.dart';
import '../../../../generated/locale_keys.g.dart';

class FileExporterWidget extends StatefulWidget {
  const FileExporterWidget({final Key? key}) : super(key: key);

  @override
  State<FileExporterWidget> createState() => _FileExporterWidgetState();
}

class _FileExporterWidgetState extends State<FileExporterWidget> {
  // Map<String, List<String>> _selectedPages = {};

  SettingsFileExporterCubit? cubit;

  @override
  Widget build(final BuildContext context) {
    return FutureBuilder<dartz.Either<WorkspaceSettingPB, FlowyError>>(
      future: FolderEventReadCurrentWorkspace().send(),
      builder: (final context, final snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final workspaces = snapshot.data?.getLeftOrNull<WorkspaceSettingPB>();
          if (workspaces != null) {
            final apps = workspaces.workspace.apps.items;
            cubit ??= SettingsFileExporterCubit(apps: apps);
            return BlocProvider<SettingsFileExporterCubit>.value(
              value: cubit!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlowyText.medium(
                    LocaleKeys.settings_files_selectFiles.tr(),
                    fontSize: 16.0,
                  ),
                  const VSpace(8),
                  const Expanded(child: _ExpandedList()),
                  const VSpace(8),
                  _buildButtons()
                ],
              ),
            );
          }
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildButtons() {
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
            await getIt<FilePickerService>()
                .getDirectoryPath()
                .then((final exportPath) async {
              if (exportPath != null && cubit != null) {
                final views = cubit!.state.selectedViews;
                final result =
                    await _AppFlowyFileExporter.exportToPath(exportPath, views);
                if (result.item1) {
                  // success
                  _showToast(LocaleKeys.settings_files_exportFileSuccess.tr());
                } else {
                  _showToast(
                    LocaleKeys.settings_files_exportFileFail.tr() +
                        result.item2.join('\n'),
                  );
                }
              } else {
                _showToast(LocaleKeys.settings_files_exportFileFail.tr());
              }
              if (mounted) {
                Navigator.of(context).popUntil(
                  (final router) => router.settings.name == '/',
                );
              }
            });
          },
        ),
      ],
    );
  }

  void _showToast(final String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: FlowyText(
          message,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ExpandedList extends StatefulWidget {
  const _ExpandedList({
    final Key? key,
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
  Widget build(final BuildContext context) {
    return BlocBuilder<SettingsFileExporterCubit, SettingsFileExportState>(
      builder: (final context, final state) {
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

  List<Widget> _buildChildren(final BuildContext context) {
    final apps = context.read<SettingsFileExporterCubit>().state.apps;
    final List<Widget> children = [];
    for (var i = 0; i < apps.length; i++) {
      children.add(_buildExpandedItem(context, i));
    }
    return children;
  }

  Widget _buildExpandedItem(final BuildContext context, final int index) {
    final state = context.read<SettingsFileExporterCubit>().state;
    final apps = state.apps;
    final expanded = state.expanded;
    final selectedItems = state.selectedItems;
    final isExpanded = expanded[index] == true;
    final List<Widget> expandedChildren = [];
    if (isExpanded) {
      for (var i = 0; i < selectedItems[index].length; i++) {
        final name = apps[index].belongings.items[i].name;
        final checkbox = CheckboxListTile(
          value: selectedItems[index][i],
          onChanged: (final value) {
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
              isExpanded
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
      final result = fold<T?>((final l) => l, (final r) => null);
      return result;
    }

    return null;
  }
}

class _AppFlowyFileExporter {
  static Future<Tuple2<bool, List<String>>> exportToPath(
    final String path,
    final List<ViewPB> views,
  ) async {
    final failedFileNames = <String>[];
    final Map<String, int> names = {};
    final documentService = DocumentService();
    for (final view in views) {
      String? content;
      String? fileExtension;
      switch (view.layout) {
        case ViewLayoutTypePB.Document:
          final document = await documentService.openDocument(view: view);
          document.fold(
            (final l) => content = l.content,
            (final r) => Log.error(r),
          );
          fileExtension = 'afdoc';
          break;
        default:
          final result = await exportDatabase(view.id);
          result.fold(
            (final pb) => content = pb.data,
            (final r) => Log.error(r),
          );
          fileExtension = 'afdb';
          break;
      }
      if (content != null) {
        final count = names.putIfAbsent(view.name, () => 0);
        final name = count == 0 ? view.name : '${view.name}($count)';
        final file = File(p.join(path, '$name.$fileExtension'));
        await file.writeAsString(content!);
        names[view.name] = count + 1;
      } else {
        failedFileNames.add(view.name);
      }
    }

    return Tuple2(failedFileNames.isEmpty, failedFileNames);
  }
}

Future<dartz.Either<ExportCSVPB, FlowyError>> exportDatabase(
  final String viewId,
) async {
  final payload = DatabaseViewIdPB.create()..value = viewId;
  return DatabaseEventExportCSV(payload).send();
}
