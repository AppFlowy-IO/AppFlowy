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
  static const GridEvent CreateField = GridEvent._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateField');
  static const GridEvent CreateEditFieldContext = GridEvent._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateEditFieldContext');
  static const GridEvent CreateRow = GridEvent._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateRow');
  static const GridEvent GetRow = GridEvent._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetRow');
  static const GridEvent UpdateCell = GridEvent._(30, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UpdateCell');

  static const $core.List<GridEvent> values = <GridEvent> [
    GetGridData,
    GetGridBlocks,
    GetFields,
    UpdateField,
    CreateField,
    CreateEditFieldContext,
    CreateRow,
    GetRow,
    UpdateCell,
  ];

  static final $core.Map<$core.int, GridEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridEvent? valueOf($core.int value) => _byValue[value];

  const GridEvent._($core.int v, $core.String n) : super(v, n);
}

