///
//  Generated code. Do not modify.
//  source: checklist_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ChecklistFilterConditionPB extends $pb.ProtobufEnum {
  static const ChecklistFilterConditionPB IsComplete = ChecklistFilterConditionPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'IsComplete');
  static const ChecklistFilterConditionPB IsIncomplete = ChecklistFilterConditionPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'IsIncomplete');

  static const $core.List<ChecklistFilterConditionPB> values = <ChecklistFilterConditionPB> [
    IsComplete,
    IsIncomplete,
  ];

  static final $core.Map<$core.int, ChecklistFilterConditionPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ChecklistFilterConditionPB? valueOf($core.int value) => _byValue[value];

  const ChecklistFilterConditionPB._($core.int v, $core.String n) : super(v, n);
}

