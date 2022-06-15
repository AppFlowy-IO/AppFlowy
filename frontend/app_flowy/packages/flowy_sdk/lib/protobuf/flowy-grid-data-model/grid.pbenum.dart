///
//  Generated code. Do not modify.
//  source: grid.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class MoveItemType extends $pb.ProtobufEnum {
  static const MoveItemType MoveField = MoveItemType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveField');
  static const MoveItemType MoveRow = MoveItemType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveRow');

  static const $core.List<MoveItemType> values = <MoveItemType> [
    MoveField,
    MoveRow,
  ];

  static final $core.Map<$core.int, MoveItemType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MoveItemType? valueOf($core.int value) => _byValue[value];

  const MoveItemType._($core.int v, $core.String n) : super(v, n);
}

