import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';

class FilterInfo {
  final FilterPB filter;
  final FieldInfo field;

  FilterInfo(this.filter, this.field);
}
