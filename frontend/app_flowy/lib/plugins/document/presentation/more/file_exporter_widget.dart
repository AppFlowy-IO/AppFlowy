import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class FileExporterWidget extends StatefulWidget {
  const FileExporterWidget({Key? key}) : super(key: key);

  @override
  State<FileExporterWidget> createState() => _FileExporterWidgetState();
}

class _FileExporterWidgetState extends State<FileExporterWidget> {
  Map<String, List<String>> _selectedPages = {};

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
          onPressed: () {
            Navigator.of(context).pop();
            // TODO: Export Data
            print(_selectedPages);
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
            return _ExpandedList(
              apps: workspaces.workspace.apps.items,
              onChanged: (selectedPages) {
                _selectedPages = selectedPages;
              },
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
    required this.apps,
    required this.onChanged,
  }) : super(key: key);

  final List<AppPB> apps;
  final void Function(Map<String, List<String>> selectedPages) onChanged;

  @override
  State<_ExpandedList> createState() => __ExpandedListState();
}

class __ExpandedListState extends State<_ExpandedList> {
  List<AppPB> get apps => widget.apps;
  List<bool> expanded = [];
  List<bool> selectedApps = [];
  List<List<bool>> selectedItems = [];

  @override
  void initState() {
    super.initState();

    expanded = apps.map((e) => true).toList();
    selectedApps = apps.map((e) => true).toList();
    selectedItems =
        apps.map((e) => e.belongings.items.map((e) => true).toList()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _buildExpandedList(context);
  }

  Widget _buildExpandedList(BuildContext context) {
    List<Widget> children = [];
    for (var i = 0; i < apps.length; i++) {
      children.add(_buildExpandedItem(context, i));
    }
    return Material(
      child: SingleChildScrollView(
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildExpandedItem(BuildContext context, int index) {
    final isExpaned = expanded[index] == true;
    List<Widget> expandedChildren = [];
    if (isExpaned) {
      for (var i = 0; i < selectedItems[index].length; i++) {
        final name = apps[index].belongings.items[i].name;
        final checkbox = CheckboxListTile(
          value: selectedItems[index][i],
          onChanged: (value) {
            setState(() {
              selectedItems[index][i] = !selectedItems[index][i];
              widget.onChanged(_getSelectedPages());
            });
          },
          title: FlowyText.regular(name),
        );
        expandedChildren.add(checkbox);
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            expanded[index] = !expanded[index];
          }),
          child: ListTile(
            title: FlowyText.regular(apps[index].name),
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

  Map<String, List<String>> _getSelectedPages() {
    Map<String, List<String>> result = {};
    for (var i = 0; i < selectedItems.length; i++) {
      final selectedItem = selectedItems[i];
      final ids = <String>[];
      for (var j = 0; j < selectedItem.length; j++) {
        if (selectedItem[j]) {
          ids.add(apps[i].belongings.items[j].id);
        }
      }
      if (ids.isNotEmpty) {
        result[apps[i].id] = ids;
      }
    }
    return result;
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
