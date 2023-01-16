///
//  Generated code. Do not modify.
//  source: checkbox_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class CheckboxFilterConditionPB extends $pb.ProtobufEnum {
  static const CheckboxFilterConditionPB IsChecked = CheckboxFilterConditionPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'IsChecked');
  static const CheckboxFilterConditionPB IsUnChecked = CheckboxFilterConditionPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'IsUnChecked');

  static const $core.List<CheckboxFilterConditionPB> values = <CheckboxFilterConditionPB> [
    IsChecked,
    IsUnChecked,
  ];

  static final $core.Map<$core.int, CheckboxFilterConditionPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CheckboxFilterConditionPB? valueOf($core.int value) => _byValue[value];

  const CheckboxFilterConditionPB._($core.int v, $core.String n) : super(v, n);
}

