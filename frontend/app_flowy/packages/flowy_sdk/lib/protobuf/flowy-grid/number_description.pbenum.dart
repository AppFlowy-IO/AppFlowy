///
//  Generated code. Do not modify.
//  source: number_description.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class MoneySymbol extends $pb.ProtobufEnum {
  static const MoneySymbol CNY = MoneySymbol._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CNY');
  static const MoneySymbol EUR = MoneySymbol._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EUR');
  static const MoneySymbol USD = MoneySymbol._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'USD');

  static const $core.List<MoneySymbol> values = <MoneySymbol> [
    CNY,
    EUR,
    USD,
  ];

  static final $core.Map<$core.int, MoneySymbol> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MoneySymbol? valueOf($core.int value) => _byValue[value];

  const MoneySymbol._($core.int v, $core.String n) : super(v, n);
}

