///
//  Generated code. Do not modify.
//  source: number_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class NumberFilterConditionPB extends $pb.ProtobufEnum {
  static const NumberFilterConditionPB Equal = NumberFilterConditionPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Equal');
  static const NumberFilterConditionPB NotEqual = NumberFilterConditionPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NotEqual');
  static const NumberFilterConditionPB GreaterThan = NumberFilterConditionPB._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GreaterThan');
  static const NumberFilterConditionPB LessThan = NumberFilterConditionPB._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LessThan');
  static const NumberFilterConditionPB GreaterThanOrEqualTo = NumberFilterConditionPB._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'GreaterThanOrEqualTo');
  static const NumberFilterConditionPB LessThanOrEqualTo = NumberFilterConditionPB._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LessThanOrEqualTo');
  static const NumberFilterConditionPB NumberIsEmpty = NumberFilterConditionPB._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NumberIsEmpty');
  static const NumberFilterConditionPB NumberIsNotEmpty = NumberFilterConditionPB._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NumberIsNotEmpty');

  static const $core.List<NumberFilterConditionPB> values = <NumberFilterConditionPB> [
    Equal,
    NotEqual,
    GreaterThan,
    LessThan,
    GreaterThanOrEqualTo,
    LessThanOrEqualTo,
    NumberIsEmpty,
    NumberIsNotEmpty,
  ];

  static final $core.Map<$core.int, NumberFilterConditionPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NumberFilterConditionPB? valueOf($core.int value) => _byValue[value];

  const NumberFilterConditionPB._($core.int v, $core.String n) : super(v, n);
}

