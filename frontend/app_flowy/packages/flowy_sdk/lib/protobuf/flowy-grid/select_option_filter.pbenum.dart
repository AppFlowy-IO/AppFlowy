///
//  Generated code. Do not modify.
//  source: select_option_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class SelectOptionConditionPB extends $pb.ProtobufEnum {
  static const SelectOptionConditionPB OptionIs = SelectOptionConditionPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OptionIs');
  static const SelectOptionConditionPB OptionIsNot = SelectOptionConditionPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OptionIsNot');
  static const SelectOptionConditionPB OptionIsEmpty = SelectOptionConditionPB._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OptionIsEmpty');
  static const SelectOptionConditionPB OptionIsNotEmpty = SelectOptionConditionPB._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OptionIsNotEmpty');

  static const $core.List<SelectOptionConditionPB> values = <SelectOptionConditionPB> [
    OptionIs,
    OptionIsNot,
    OptionIsEmpty,
    OptionIsNotEmpty,
  ];

  static final $core.Map<$core.int, SelectOptionConditionPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SelectOptionConditionPB? valueOf($core.int value) => _byValue[value];

  const SelectOptionConditionPB._($core.int v, $core.String n) : super(v, n);
}

