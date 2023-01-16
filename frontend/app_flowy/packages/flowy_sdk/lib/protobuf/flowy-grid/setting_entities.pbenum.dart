///
//  Generated code. Do not modify.
//  source: setting_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class GridLayout extends $pb.ProtobufEnum {
  static const GridLayout Table = GridLayout._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Table');
  static const GridLayout Board = GridLayout._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Board');

  static const $core.List<GridLayout> values = <GridLayout> [
    Table,
    Board,
  ];

  static final $core.Map<$core.int, GridLayout> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridLayout? valueOf($core.int value) => _byValue[value];

  const GridLayout._($core.int v, $core.String n) : super(v, n);
}

