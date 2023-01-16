///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class GridEvent extends $pb.ProtobufEnum {
  static const GridEvent GetGrid = GridEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetGrid');
  static const GridEvent GetGridSetting = GridEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetGridSetting');
  static const GridEvent UpdateGridSetting = GridEvent._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateGridSetting');
  static const GridEvent GetAllFilters = GridEvent._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetAllFilters');
  static const GridEvent GetFields = GridEvent._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetFields');
  static const GridEvent UpdateField = GridEvent._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateField');
  static const GridEvent UpdateFieldTypeOption = GridEvent._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateFieldTypeOption');
  static const GridEvent DeleteField = GridEvent._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteField');
  static const GridEvent SwitchToField = GridEvent._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SwitchToField');
  static const GridEvent DuplicateField = GridEvent._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DuplicateField');
  static const GridEvent MoveField = GridEvent._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveField');
  static const GridEvent GetFieldTypeOption = GridEvent._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetFieldTypeOption');
  static const GridEvent CreateFieldTypeOption = GridEvent._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateFieldTypeOption');
  static const GridEvent NewSelectOption = GridEvent._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NewSelectOption');
  static const GridEvent GetSelectOptionCellData = GridEvent._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetSelectOptionCellData');
  static const GridEvent UpdateSelectOption = GridEvent._(32, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateSelectOption');
  static const GridEvent CreateTableRow = GridEvent._(50, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateTableRow');
  static const GridEvent GetRow = GridEvent._(51, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetRow');
  static const GridEvent DeleteRow = GridEvent._(52, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteRow');
  static const GridEvent DuplicateRow = GridEvent._(53, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DuplicateRow');
  static const GridEvent MoveRow = GridEvent._(54, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveRow');
  static const GridEvent GetCell = GridEvent._(70, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetCell');
  static const GridEvent UpdateCell = GridEvent._(71, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateCell');
  static const GridEvent UpdateSelectOptionCell = GridEvent._(72, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateSelectOptionCell');
  static const GridEvent UpdateDateCell = GridEvent._(80, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateDateCell');
  static const GridEvent GetGroup = GridEvent._(100, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetGroup');
  static const GridEvent CreateBoardCard = GridEvent._(110, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateBoardCard');
  static const GridEvent MoveGroup = GridEvent._(111, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveGroup');
  static const GridEvent MoveGroupRow = GridEvent._(112, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveGroupRow');
  static const GridEvent GroupByField = GridEvent._(113, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GroupByField');

  static const $core.List<GridEvent> values = <GridEvent> [
    GetGrid,
    GetGridSetting,
    UpdateGridSetting,
    GetAllFilters,
    GetFields,
    UpdateField,
    UpdateFieldTypeOption,
    DeleteField,
    SwitchToField,
    DuplicateField,
    MoveField,
    GetFieldTypeOption,
    CreateFieldTypeOption,
    NewSelectOption,
    GetSelectOptionCellData,
    UpdateSelectOption,
    CreateTableRow,
    GetRow,
    DeleteRow,
    DuplicateRow,
    MoveRow,
    GetCell,
    UpdateCell,
    UpdateSelectOptionCell,
    UpdateDateCell,
    GetGroup,
    CreateBoardCard,
    MoveGroup,
    MoveGroupRow,
    GroupByField,
  ];

  static final $core.Map<$core.int, GridEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridEvent? valueOf($core.int value) => _byValue[value];

  const GridEvent._($core.int v, $core.String n) : super(v, n);
}

