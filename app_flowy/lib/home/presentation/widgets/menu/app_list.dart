import 'package:expandable/expandable.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:app_flowy/home/presentation/widgets/app/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

class AppList extends StatelessWidget {
  final Option<List<App>> apps;
  const AppList({required this.apps, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return apps.fold(() {
      return const Text('You have no apps, create one?');
    }, (apps) {
      return ExpandableTheme(
          data: const ExpandableThemeData(
            iconColor: Colors.blue,
            useInkWell: true,
          ),
          child: Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: apps.map((app) => AppWidget(app)).toList(),
            ),
          ));
    });
  }
}
