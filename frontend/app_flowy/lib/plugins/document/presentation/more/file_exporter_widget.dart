import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter/material.dart';

class FileExporterWidget extends StatefulWidget {
  const FileExporterWidget({Key? key}) : super(key: key);

  @override
  State<FileExporterWidget> createState() => _FileExporterWidgetState();
}

class _FileExporterWidgetState extends State<FileExporterWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dartz.Either<WorkspaceSettingPB, FlowyError>>(
      future: FolderEventReadCurrentWorkspace().send(),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final workspaces = snapshot.data?.getLeftOrNull<WorkspaceSettingPB>();
          if (workspaces != null) {
            return _ExpandedList(
              apps: workspaces.workspace.apps.items,
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
  }) : super(key: key);

  final List<AppPB> apps;

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

    expanded = apps.map((e) => false).toList();
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
    List<Widget> expandedChildren = [];
    if (expanded[index] == true) {
      for (var i = 0; i < selectedItems[index].length; i++) {
        final name = apps[index].belongings.items[i].name;
        final checkbox = CheckboxListTile(
          value: selectedItems[index][i],
          onChanged: (value) {
            setState(() {
              selectedItems[index][i] = !selectedItems[index][i];
            });
          },
          title: Text(name),
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
            // value: selectedApps[index],
            // onChanged: (value) {
            //   setState(() {
            //     selectedApps[index] = !selectedApps[index];
            //   });
            // },
            title: Text(apps[index].name),
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
