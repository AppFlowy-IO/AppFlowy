///
//  Generated code. Do not modify.
//  source: text_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class TextFilterConditionPB extends $pb.ProtobufEnum {
  static const TextFilterConditionPB Is = TextFilterConditionPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Is');
  static const TextFilterConditionPB IsNot = TextFilterConditionPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'IsNot');
  static const TextFilterConditionPB Contains = TextFilterConditionPB._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Contains');
  static const TextFilterConditionPB DoesNotContain = TextFilterConditionPB._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DoesNotContain');
  static const TextFilterConditionPB StartsWith = TextFilterConditionPB._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'StartsWith');
  static const TextFilterConditionPB EndsWith = TextFilterConditionPB._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EndsWith');
  static const TextFilterConditionPB TextIsEmpty = TextFilterConditionPB._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TextIsEmpty');
  static const TextFilterConditionPB TextIsNotEmpty = TextFilterConditionPB._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TextIsNotEmpty');

  static const $core.List<TextFilterConditionPB> values = <TextFilterConditionPB> [
    Is,
    IsNot,
    Contains,
    DoesNotContain,
    StartsWith,
    EndsWith,
    TextIsEmpty,
    TextIsNotEmpty,
  ];

  static final $core.Map<$core.int, TextFilterConditionPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TextFilterConditionPB? valueOf($core.int value) => _byValue[value];

  const TextFilterConditionPB._($core.int v, $core.String n) : super(v, n);
}

