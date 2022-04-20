import 'package:app_flowy/workspace/application/grid/row/row_detail_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_size/window_size.dart';

class RowDetailPage extends StatelessWidget with FlowyOverlayDelegate {
  final GridRow rowData;
  final GridRowCache rowCache;

  const RowDetailPage({
    required this.rowData,
    required this.rowCache,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RowDetailBloc(rowData: rowData, rowCache: rowCache),
      child: Container(),
    );
  }

  void show(BuildContext context) async {
    FlowyOverlay.of(context).remove(identifier());

    const size = Size(460, 400);
    final window = await getWindowInfo();
    FlowyOverlay.of(context).insertWithRect(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.tight(const Size(460, 400)),
      ),
      identifier: identifier(),
      anchorPosition: Offset(-size.width / 2.0, -size.height / 2.0),
      anchorSize: window.frame.size,
      anchorDirection: AnchorDirection.center,
      style: FlowyOverlayStyle(blur: false),
      delegate: this,
    );
  }

  static String identifier() {
    return (RowDetailPage).toString();
  }
}
