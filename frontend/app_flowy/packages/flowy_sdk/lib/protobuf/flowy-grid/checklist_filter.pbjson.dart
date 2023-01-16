///
//  Generated code. Do not modify.
//  source: checklist_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use checklistFilterConditionPBDescriptor instead')
const ChecklistFilterConditionPB$json = const {
  '1': 'ChecklistFilterConditionPB',
  '2': const [
    const {'1': 'IsComplete', '2': 0},
    const {'1': 'IsIncomplete', '2': 1},
  ],
};

/// Descriptor for `ChecklistFilterConditionPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List checklistFilterConditionPBDescriptor = $convert.base64Decode('ChpDaGVja2xpc3RGaWx0ZXJDb25kaXRpb25QQhIOCgpJc0NvbXBsZXRlEAASEAoMSXNJbmNvbXBsZXRlEAE=');
@$core.Deprecated('Use checklistFilterPBDescriptor instead')
const ChecklistFilterPB$json = const {
  '1': 'ChecklistFilterPB',
  '2': const [
    const {'1': 'condition', '3': 1, '4': 1, '5': 14, '6': '.ChecklistFilterConditionPB', '10': 'condition'},
  ],
};

/// Descriptor for `ChecklistFilterPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checklistFilterPBDescriptor = $convert.base64Decode('ChFDaGVja2xpc3RGaWx0ZXJQQhI5Cgljb25kaXRpb24YASABKA4yGy5DaGVja2xpc3RGaWx0ZXJDb25kaXRpb25QQlIJY29uZGl0aW9u');
