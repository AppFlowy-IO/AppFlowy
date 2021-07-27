import 'package:app_flowy/workspace/presentation/view/view_widget.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flowy_infra_ui/style_widget/styled_hover.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

class ViewList extends StatelessWidget {
  final Option<List<View>> views;
  const ViewList(this.views, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Log.info('ViewList build');
    return views.fold(
      () => const SizedBox(),
      (views) {
        return Column(
          children: _renderViewWidgets(views),
        );
      },
    );
  }

  List<Widget> _renderViewWidgets(List<View> views) {
    var targetViews = views.map((view) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: StyledHover(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
          child: ViewWidget(
            view: view,
          ),
        ),
      );
    }).toList(growable: false);
    return targetViews;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    views.fold(() => {},
        (views) => properties.add(IterableProperty<View>('views', views)));
  }
}
