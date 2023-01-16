///
//  Generated code. Do not modify.
//  source: configuration.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class DateCondition extends $pb.ProtobufEnum {
  static const DateCondition Relative = DateCondition._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Relative');
  static const DateCondition Day = DateCondition._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Day');
  static const DateCondition Week = DateCondition._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Week');
  static const DateCondition Month = DateCondition._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Month');
  static const DateCondition Year = DateCondition._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Year');

  static const $core.List<DateCondition> values = <DateCondition> [
    Relative,
    Day,
    Week,
    Month,
    Year,
  ];

  static final $core.Map<$core.int, DateCondition> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DateCondition? valueOf($core.int value) => _byValue[value];

  const DateCondition._($core.int v, $core.String n) : super(v, n);
}

