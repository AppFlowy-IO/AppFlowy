///
//  Generated code. Do not modify.
//  source: grid.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class FieldType extends $pb.ProtobufEnum {
  static const FieldType RichText = FieldType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'RichText');
  static const FieldType Number = FieldType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Number');
  static const FieldType DateTime = FieldType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateTime');
  static const FieldType SingleSelect = FieldType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SingleSelect');
  static const FieldType MultiSelect = FieldType._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MultiSelect');
  static const FieldType Checkbox = FieldType._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Checkbox');

  static const $core.List<FieldType> values = <FieldType> [
    RichText,
    Number,
    DateTime,
    SingleSelect,
    MultiSelect,
    Checkbox,
  ];

  static final $core.Map<$core.int, FieldType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FieldType? valueOf($core.int value) => _byValue[value];

  const FieldType._($core.int v, $core.String n) : super(v, n);
}

