///
//  Generated code. Do not modify.
//  source: date_type_option_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class DateFormat extends $pb.ProtobufEnum {
  static const DateFormat Local = DateFormat._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Local');
  static const DateFormat US = DateFormat._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'US');
  static const DateFormat ISO = DateFormat._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ISO');
  static const DateFormat Friendly = DateFormat._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Friendly');

  static const $core.List<DateFormat> values = <DateFormat> [
    Local,
    US,
    ISO,
    Friendly,
  ];

  static final $core.Map<$core.int, DateFormat> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DateFormat? valueOf($core.int value) => _byValue[value];

  const DateFormat._($core.int v, $core.String n) : super(v, n);
}

class TimeFormat extends $pb.ProtobufEnum {
  static const TimeFormat TwelveHour = TimeFormat._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TwelveHour');
  static const TimeFormat TwentyFourHour = TimeFormat._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TwentyFourHour');

  static const $core.List<TimeFormat> values = <TimeFormat> [
    TwelveHour,
    TwentyFourHour,
  ];

  static final $core.Map<$core.int, TimeFormat> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TimeFormat? valueOf($core.int value) => _byValue[value];

  const TimeFormat._($core.int v, $core.String n) : super(v, n);
}

