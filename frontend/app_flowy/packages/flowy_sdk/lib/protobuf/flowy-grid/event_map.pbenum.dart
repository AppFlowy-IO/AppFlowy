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
  static const GridEvent CreateGrid = GridEvent._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateGrid');
  static const GridEvent OpenGrid = GridEvent._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OpenGrid');
  static const GridEvent GetRows = GridEvent._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetRows');
  static const GridEvent GetFields = GridEvent._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GetFields');
  static const GridEvent CreateRow = GridEvent._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CreateRow');

  static const $core.List<GridEvent> values = <GridEvent> [
    CreateGrid,
    OpenGrid,
    GetRows,
    GetFields,
    CreateRow,
  ];

  static final $core.Map<$core.int, GridEvent> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridEvent? valueOf($core.int value) => _byValue[value];

  const GridEvent._($core.int v, $core.String n) : super(v, n);
}

