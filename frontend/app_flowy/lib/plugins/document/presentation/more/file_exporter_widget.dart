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
  List<AppPB> apps = [];
  List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dartz.Either<WorkspaceSettingPB, FlowyError>>(
        future: FolderEventReadCurrentWorkspace().send(),
        builder: ((context, snapshot) {
          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            final workspaces =
                snapshot.data?.getLeftOrNull<WorkspaceSettingPB>();
            if (workspaces != null) {
              apps = workspaces.workspace.apps.items;
              if (expanded.isEmpty) {
                expanded = apps.map((e) => true).toList();
              }
              return _buildExpandedList(context);
            }
          }
          return const CircularProgressIndicator();
        }));
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            expanded[index] = !expanded[index];
          }),
          child: CheckboxListTile(
            value: expanded[index],
            onChanged: (value) {
              setState(() {
                expanded[index] = !expanded[index];
              });
            },
            title: Text(apps[index].name),
          ),
        ),
        if (expanded[index] == true)
          ...apps[index]
              .belongings
              .items
              .map((e) => CheckboxListTile(
                    value: false,
                    onChanged: (value) {},
                    title: Text(e.name),
                  ))
              .toList(),
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
