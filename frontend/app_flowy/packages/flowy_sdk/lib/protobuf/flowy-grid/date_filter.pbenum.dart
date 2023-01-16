///
//  Generated code. Do not modify.
//  source: date_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class DateFilterConditionPB extends $pb.ProtobufEnum {
  static const DateFilterConditionPB DateIs = DateFilterConditionPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateIs');
  static const DateFilterConditionPB DateBefore = DateFilterConditionPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateBefore');
  static const DateFilterConditionPB DateAfter = DateFilterConditionPB._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateAfter');
  static const DateFilterConditionPB DateOnOrBefore = DateFilterConditionPB._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateOnOrBefore');
  static const DateFilterConditionPB DateOnOrAfter = DateFilterConditionPB._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateOnOrAfter');
  static const DateFilterConditionPB DateWithIn = DateFilterConditionPB._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateWithIn');
  static const DateFilterConditionPB DateIsEmpty = DateFilterConditionPB._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateIsEmpty');
  static const DateFilterConditionPB DateIsNotEmpty = DateFilterConditionPB._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DateIsNotEmpty');

  static const $core.List<DateFilterConditionPB> values = <DateFilterConditionPB> [
    DateIs,
    DateBefore,
    DateAfter,
    DateOnOrBefore,
    DateOnOrAfter,
    DateWithIn,
    DateIsEmpty,
    DateIsNotEmpty,
  ];

  static final $core.Map<$core.int, DateFilterConditionPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DateFilterConditionPB? valueOf($core.int value) => _byValue[value];

  const DateFilterConditionPB._($core.int v, $core.String n) : super(v, n);
}

