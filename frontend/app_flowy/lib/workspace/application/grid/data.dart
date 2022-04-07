import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';

class GridHeaderData {
  final String gridId;
  final List<Field> fields;

  GridHeaderData({required this.gridId, required this.fields});
}
