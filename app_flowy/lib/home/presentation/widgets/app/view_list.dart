import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

class ViewList extends StatelessWidget {
  final List<View> views;
  const ViewList(this.views, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Log.info('ViewList build');
    if (views.isEmpty) {
      return const SizedBox(
        height: 30,
      );
    } else {
      return Column(
        children: buildViewWidgets(),
      ).padding(vertical: Insets.sm);
    }
  }

  List<ViewWidget> buildViewWidgets() {
    var targetViews = views.map((view) {
      return ViewWidget(
        icon: const Icon(Icons.file_copy),
        view: view,
      );
    }).toList(growable: true);
    targetViews.addAll(_mockViewWidgets());
    return targetViews;
  }

  // TODO: junlin - remove view mocker after integrate docs storage to db
  List<ViewWidget> _mockViewWidgets() {
    // Stub doc views
    final docViews = _mockDocsViews();
    return docViews.map((view) {
      return ViewWidget(
        icon: Icon(Icons.edit_sharp),
        view: view,
      );
    }).toList(growable: false);
  }

  // TODO: junlin - remove view mocker after integrate docs storage to db
  List<View> _mockDocsViews() {
    // plain text doc
    var plainTextView = View();
    plainTextView.id = 'doc_plain_text_document';
    plainTextView.name = 'Plain Text Doc';
    // code blocks doc

    return [plainTextView];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<View>('views', views));
  }
}

class ViewWidget extends StatelessWidget {
  final View view;
  final Widget icon;
  const ViewWidget({Key? key, required this.view, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: _handleTapOnView(context),
        child: Container(
          height: 30,
          child: buildContent(),
        ));
  }

  Row buildContent() {
    return Row(
      children: [
        icon,
        const SizedBox(
          width: 4,
        ),
        Text(
          view.name,
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 15),
        )
      ],
    );
  }

  Function() _handleTapOnView(BuildContext context) {
    return () {
      // if (view.id.startsWith('doc')) {
      //   context.read<MenuBloc>().add(MenuEvent.openPage(DocPageContext(view)));
      //   return;
      // }

      // context.read<MenuBloc>().add(MenuEvent.openPage(GridPageContext(view)));
    };
  }
}
