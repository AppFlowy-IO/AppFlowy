///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class GridEvent extends $pb.ProtobufEnum {
  static const GridEvent GetGridData = GridEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetGridData');
  static const GridEvent GetGridBlocks = GridEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetGridBlocks');
  static const GridEvent GetFields = GridEvent._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetFields');
  static const GridEvent UpdateField = GridEvent._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateField');
  static const GridEvent UpdateFieldTypeOption = GridEvent._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateFieldTypeOption');
  static const GridEvent InsertField = GridEvent._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'InsertField');
  static const GridEvent DeleteField = GridEvent._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteField');
  static const GridEvent SwitchToField = GridEvent._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SwitchToField');
  static const GridEvent DuplicateField = GridEvent._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DuplicateField');
  static const GridEvent MoveItem = GridEvent._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveItem');
  static const GridEvent GetFieldTypeOption = GridEvent._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetFieldTypeOption');
  static const GridEvent CreateFieldTypeOption = GridEvent._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateFieldTypeOption');
  static const GridEvent NewSelectOption = GridEvent._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NewSelectOption');
  static const GridEvent GetSelectOptionCellData = GridEvent._(31, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetSelectOptionCellData');
  static const GridEvent UpdateSelectOption = GridEvent._(32, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateSelectOption');
  static const GridEvent CreateRow = GridEvent._(50, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateRow');
  static const GridEvent GetRow = GridEvent._(51, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetRow');
  static const GridEvent DeleteRow = GridEvent._(52, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeleteRow');
  static const GridEvent DuplicateRow = GridEvent._(53, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DuplicateRow');
  static const GridEvent GetCell = GridEvent._(70, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetCell');
  static const GridEvent UpdateCell = GridEvent._(71, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateCell');
  static const GridEvent UpdateSelectOptionCell = GridEvent._(72, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateSelectOptionCell');
  static const GridEvent UpdateDateCell = GridEvent._(80, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateDateCell');
  static const GridEvent GetDateCellData = GridEvent._(90, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetDateCellData');

  static const $core.List<GridEvent> values = <GridEvent> [
    GetGridData,
    GetGridBlocks,
    GetFields,
    UpdateField,
    UpdateFieldTypeOption,
    InsertField,
    DeleteField,
    SwitchToField,
    DuplicateField,
    MoveItem,
    GetFieldTypeOption,
    CreateFieldTypeOption,
    NewSelectOption,
    GetSelectOptionCellData,
    UpdateSelectOption,
    CreateRow,
    GetRow,
    DeleteRow,
    DuplicateRow,
    GetCell,
    UpdateCell,
    UpdateSelectOptionCell,
    UpdateDateCell,
    GetDateCellData,
  ];

  static final $core.Map<$core.int, GridEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridEvent? valueOf($core.int value) => _byValue[value];

  const GridEvent._($core.int v, $core.String n) : super(v, n);
}

