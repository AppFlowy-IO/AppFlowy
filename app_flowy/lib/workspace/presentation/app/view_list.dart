import 'package:app_flowy/workspace/presentation/view/view_widget.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:styled_widget/styled_widget.dart';

class ViewList extends StatelessWidget {
  final Option<List<View>> views;
  const ViewList(this.views, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Log.info('ViewList build');
    return views.fold(
      () => const SizedBox(
        height: 10,
      ),
      (views) {
        return Column(
          children: buildViewWidgets(views),
        ).padding(vertical: Insets.sm);
      },
    );
  }

  List<ViewWidget> buildViewWidgets(List<View> views) {
    var targetViews = views.map((view) {
      return ViewWidget(
        icon: const Icon(Icons.file_copy),
        view: view,
      );
    }).toList(growable: true);
    return targetViews;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    views.fold(() => {},
        (views) => properties.add(IterableProperty<View>('views', views)));
  }
}
