import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/export/document_exporter.dart';
import 'package:appflowy/workspace/application/settings/settings_file_exporter_cubit.dart';
import 'package:appflowy/workspace/application/settings/share/export_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart' hide WidgetBuilder;
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../../../../generated/locale_keys.g.dart';

class FileExporterWidget extends StatefulWidget {
  const FileExporterWidget({Key? key}) : super(key: key);

  @override
  State<FileExporterWidget> createState() => _FileExporterWidgetState();
}

class _FileExporterWidgetState extends State<FileExporterWidget> {
  // Map<String, List<String>> _selectedPages = {};

  SettingsFileExporterCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dartz.Either<WorkspaceSettingPB, FlowyError>>(
      future: FolderEventGetCurrentWorkspace().send(),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final workspaces = snapshot.data?.getLeftOrNull<WorkspaceSettingPB>();
          if (workspaces != null) {
            final views = workspaces.workspace.views;
            cubit ??= SettingsFileExporterCubit(views: views);
            return BlocProvider<SettingsFileExporterCubit>.value(
              value: cubit!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FlowyText.medium(
                        LocaleKeys.settings_files_selectFiles.tr(),
                        fontSize: 16.0,
                      ),
                      BlocBuilder<SettingsFileExporterCubit,
                          SettingsFileExportState>(
                        builder: (context, state) => FlowyTextButton(
                          state.selectedItems
                                  .expand((element) => element)
                                  .every((element) => element)
                              ? LocaleKeys.settings_files_deselectAll.tr()
                              : LocaleKeys.settings_files_selectAll.tr(),
                          onPressed: () {
                            context
                                .read<SettingsFileExporterCubit>()
                                .selectOrDeselectAllItems();
                          },
                        ),
                      )
                    ],
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
                .then((exportPath) async {
              if (exportPath != null && cubit != null) {
                final views = cubit!.state.selectedViews;
                final result =
                    await _AppFlowyFileExporter.exportToPath(exportPath, views);
                if (result.$1) {
                  // success
                  _showToast(LocaleKeys.settings_files_exportFileSuccess.tr());
                } else {
                  _showToast(
                    LocaleKeys.settings_files_exportFileFail.tr() +
                        result.$2.join('\n'),
                  );
                }
              } else {
                _showToast(LocaleKeys.settings_files_exportFileFail.tr());
              }
              if (mounted) {
                Navigator.of(context).popUntil(
                  (router) => router.settings.name == '/',
                );
              }
            });
          },
        ),
      ],
    );
  }

  void _showToast(String message) {
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
    final apps = context.read<SettingsFileExporterCubit>().state.views;
    final List<Widget> children = [];
    for (var i = 0; i < apps.length; i++) {
      children.add(_buildExpandedItem(context, i));
    }
    return children;
  }

  Widget _buildExpandedItem(BuildContext context, int index) {
    final state = context.read<SettingsFileExporterCubit>().state;
    final apps = state.views;
    final expanded = state.expanded;
    final selectedItems = state.selectedItems;
    final isExpanded = expanded[index] == true;
    final List<Widget> expandedChildren = [];
    if (isExpanded) {
      for (var i = 0; i < selectedItems[index].length; i++) {
        final name = apps[index].childViews[i].name;
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
      final result = fold<T?>((l) => l, (r) => null);
      return result;
    }

    return null;
  }
}

class _AppFlowyFileExporter {
  static Future<(bool result, List<String> failedNames)> exportToPath(
    String path,
    List<ViewPB> views,
  ) async {
    final failedFileNames = <String>[];
    final Map<String, int> names = {};
    for (final view in views) {
      String? content;
      String? fileExtension;
      switch (view.layout) {
        case ViewLayoutPB.Document:
          final documentExporter = DocumentExporter(view);
          final result = await documentExporter.export(
            DocumentExportType.json,
          );
          result.fold((l) => Log.error(l), (json) {
            content = json;
          });
          fileExtension = 'afdocument';
          break;
        default:
          final result =
              await BackendExportService.exportDatabaseAsCSV(view.id);
          result.fold(
            (l) => content = l.data,
            (r) => Log.error(r),
          );
          fileExtension = 'csv';
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

    return (failedFileNames.isEmpty, failedFileNames);
  }
}
