///
//  Generated code. Do not modify.
//  source: number_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class NumberFormat extends $pb.ProtobufEnum {
  static const NumberFormat Number = NumberFormat._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Number');
  static const NumberFormat USD = NumberFormat._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'USD');
  static const NumberFormat CNY = NumberFormat._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CNY');
  static const NumberFormat EUR = NumberFormat._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EUR');

  static const $core.List<NumberFormat> values = <NumberFormat> [
    Number,
    USD,
    CNY,
    EUR,
  ];

  static final $core.Map<$core.int, NumberFormat> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NumberFormat? valueOf($core.int value) => _byValue[value];

  const NumberFormat._($core.int v, $core.String n) : super(v, n);
}

