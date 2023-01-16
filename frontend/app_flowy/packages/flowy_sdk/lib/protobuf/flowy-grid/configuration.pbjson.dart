///
//  Generated code. Do not modify.
//  source: configuration.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use dateConditionDescriptor instead')
const DateCondition$json = const {
  '1': 'DateCondition',
  '2': const [
    const {'1': 'Relative', '2': 0},
    const {'1': 'Day', '2': 1},
    const {'1': 'Week', '2': 2},
    const {'1': 'Month', '2': 3},
    const {'1': 'Year', '2': 4},
  ],
};

/// Descriptor for `DateCondition`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List dateConditionDescriptor = $convert.base64Decode('Cg1EYXRlQ29uZGl0aW9uEgwKCFJlbGF0aXZlEAASBwoDRGF5EAESCAoEV2VlaxACEgkKBU1vbnRoEAMSCAoEWWVhchAE');
@$core.Deprecated('Use urlGroupConfigurationPBDescriptor instead')
const UrlGroupConfigurationPB$json = const {
  '1': 'UrlGroupConfigurationPB',
  '2': const [
    const {'1': 'hide_empty', '3': 1, '4': 1, '5': 8, '10': 'hideEmpty'},
  ],
};

/// Descriptor for `UrlGroupConfigurationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List urlGroupConfigurationPBDescriptor = $convert.base64Decode('ChdVcmxHcm91cENvbmZpZ3VyYXRpb25QQhIdCgpoaWRlX2VtcHR5GAEgASgIUgloaWRlRW1wdHk=');
@$core.Deprecated('Use textGroupConfigurationPBDescriptor instead')
const TextGroupConfigurationPB$json = const {
  '1': 'TextGroupConfigurationPB',
  '2': const [
    const {'1': 'hide_empty', '3': 1, '4': 1, '5': 8, '10': 'hideEmpty'},
  ],
};

/// Descriptor for `TextGroupConfigurationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textGroupConfigurationPBDescriptor = $convert.base64Decode('ChhUZXh0R3JvdXBDb25maWd1cmF0aW9uUEISHQoKaGlkZV9lbXB0eRgBIAEoCFIJaGlkZUVtcHR5');
@$core.Deprecated('Use selectOptionGroupConfigurationPBDescriptor instead')
const SelectOptionGroupConfigurationPB$json = const {
  '1': 'SelectOptionGroupConfigurationPB',
  '2': const [
    const {'1': 'hide_empty', '3': 1, '4': 1, '5': 8, '10': 'hideEmpty'},
  ],
};

/// Descriptor for `SelectOptionGroupConfigurationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionGroupConfigurationPBDescriptor = $convert.base64Decode('CiBTZWxlY3RPcHRpb25Hcm91cENvbmZpZ3VyYXRpb25QQhIdCgpoaWRlX2VtcHR5GAEgASgIUgloaWRlRW1wdHk=');
@$core.Deprecated('Use groupRecordPBDescriptor instead')
const GroupRecordPB$json = const {
  '1': 'GroupRecordPB',
  '2': const [
    const {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'visible', '3': 2, '4': 1, '5': 8, '10': 'visible'},
  ],
};

/// Descriptor for `GroupRecordPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupRecordPBDescriptor = $convert.base64Decode('Cg1Hcm91cFJlY29yZFBCEhkKCGdyb3VwX2lkGAEgASgJUgdncm91cElkEhgKB3Zpc2libGUYAiABKAhSB3Zpc2libGU=');
@$core.Deprecated('Use numberGroupConfigurationPBDescriptor instead')
const NumberGroupConfigurationPB$json = const {
  '1': 'NumberGroupConfigurationPB',
  '2': const [
    const {'1': 'hide_empty', '3': 1, '4': 1, '5': 8, '10': 'hideEmpty'},
  ],
};

/// Descriptor for `NumberGroupConfigurationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List numberGroupConfigurationPBDescriptor = $convert.base64Decode('ChpOdW1iZXJHcm91cENvbmZpZ3VyYXRpb25QQhIdCgpoaWRlX2VtcHR5GAEgASgIUgloaWRlRW1wdHk=');
@$core.Deprecated('Use dateGroupConfigurationPBDescriptor instead')
const DateGroupConfigurationPB$json = const {
  '1': 'DateGroupConfigurationPB',
  '2': const [
    const {'1': 'condition', '3': 1, '4': 1, '5': 14, '6': '.DateCondition', '10': 'condition'},
    const {'1': 'hide_empty', '3': 2, '4': 1, '5': 8, '10': 'hideEmpty'},
  ],
};

/// Descriptor for `DateGroupConfigurationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dateGroupConfigurationPBDescriptor = $convert.base64Decode('ChhEYXRlR3JvdXBDb25maWd1cmF0aW9uUEISLAoJY29uZGl0aW9uGAEgASgOMg4uRGF0ZUNvbmRpdGlvblIJY29uZGl0aW9uEh0KCmhpZGVfZW1wdHkYAiABKAhSCWhpZGVFbXB0eQ==');
@$core.Deprecated('Use checkboxGroupConfigurationPBDescriptor instead')
const CheckboxGroupConfigurationPB$json = const {
  '1': 'CheckboxGroupConfigurationPB',
  '2': const [
    const {'1': 'hide_empty', '3': 1, '4': 1, '5': 8, '10': 'hideEmpty'},
  ],
};

/// Descriptor for `CheckboxGroupConfigurationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkboxGroupConfigurationPBDescriptor = $convert.base64Decode('ChxDaGVja2JveEdyb3VwQ29uZmlndXJhdGlvblBCEh0KCmhpZGVfZW1wdHkYASABKAhSCWhpZGVFbXB0eQ==');
