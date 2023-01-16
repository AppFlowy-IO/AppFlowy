///
//  Generated code. Do not modify.
//  source: setting_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use gridLayoutDescriptor instead')
const GridLayout$json = const {
  '1': 'GridLayout',
  '2': const [
    const {'1': 'Table', '2': 0},
    const {'1': 'Board', '2': 1},
  ],
};

/// Descriptor for `GridLayout`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gridLayoutDescriptor = $convert.base64Decode('CgpHcmlkTGF5b3V0EgkKBVRhYmxlEAASCQoFQm9hcmQQAQ==');
@$core.Deprecated('Use gridSettingPBDescriptor instead')
const GridSettingPB$json = const {
  '1': 'GridSettingPB',
  '2': const [
    const {'1': 'layouts', '3': 1, '4': 3, '5': 11, '6': '.GridLayoutPB', '10': 'layouts'},
    const {'1': 'layout_type', '3': 2, '4': 1, '5': 14, '6': '.GridLayout', '10': 'layoutType'},
    const {'1': 'filters', '3': 3, '4': 1, '5': 11, '6': '.RepeatedFilterPB', '10': 'filters'},
    const {'1': 'group_configurations', '3': 4, '4': 1, '5': 11, '6': '.RepeatedGroupConfigurationPB', '10': 'groupConfigurations'},
  ],
};

/// Descriptor for `GridSettingPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridSettingPBDescriptor = $convert.base64Decode('Cg1HcmlkU2V0dGluZ1BCEicKB2xheW91dHMYASADKAsyDS5HcmlkTGF5b3V0UEJSB2xheW91dHMSLAoLbGF5b3V0X3R5cGUYAiABKA4yCy5HcmlkTGF5b3V0UgpsYXlvdXRUeXBlEisKB2ZpbHRlcnMYAyABKAsyES5SZXBlYXRlZEZpbHRlclBCUgdmaWx0ZXJzElAKFGdyb3VwX2NvbmZpZ3VyYXRpb25zGAQgASgLMh0uUmVwZWF0ZWRHcm91cENvbmZpZ3VyYXRpb25QQlITZ3JvdXBDb25maWd1cmF0aW9ucw==');
@$core.Deprecated('Use gridLayoutPBDescriptor instead')
const GridLayoutPB$json = const {
  '1': 'GridLayoutPB',
  '2': const [
    const {'1': 'ty', '3': 1, '4': 1, '5': 14, '6': '.GridLayout', '10': 'ty'},
  ],
};

/// Descriptor for `GridLayoutPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridLayoutPBDescriptor = $convert.base64Decode('CgxHcmlkTGF5b3V0UEISGwoCdHkYASABKA4yCy5HcmlkTGF5b3V0UgJ0eQ==');
@$core.Deprecated('Use gridSettingChangesetPBDescriptor instead')
const GridSettingChangesetPB$json = const {
  '1': 'GridSettingChangesetPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'layout_type', '3': 2, '4': 1, '5': 14, '6': '.GridLayout', '10': 'layoutType'},
    const {'1': 'alter_filter', '3': 3, '4': 1, '5': 11, '6': '.AlterFilterPayloadPB', '9': 0, '10': 'alterFilter'},
    const {'1': 'delete_filter', '3': 4, '4': 1, '5': 11, '6': '.DeleteFilterPayloadPB', '9': 1, '10': 'deleteFilter'},
    const {'1': 'insert_group', '3': 5, '4': 1, '5': 11, '6': '.InsertGroupPayloadPB', '9': 2, '10': 'insertGroup'},
    const {'1': 'delete_group', '3': 6, '4': 1, '5': 11, '6': '.DeleteGroupPayloadPB', '9': 3, '10': 'deleteGroup'},
    const {'1': 'alter_sort', '3': 7, '4': 1, '5': 11, '6': '.AlterSortPayloadPB', '9': 4, '10': 'alterSort'},
    const {'1': 'delete_sort', '3': 8, '4': 1, '5': 11, '6': '.DeleteSortPayloadPB', '9': 5, '10': 'deleteSort'},
  ],
  '8': const [
    const {'1': 'one_of_alter_filter'},
    const {'1': 'one_of_delete_filter'},
    const {'1': 'one_of_insert_group'},
    const {'1': 'one_of_delete_group'},
    const {'1': 'one_of_alter_sort'},
    const {'1': 'one_of_delete_sort'},
  ],
};

/// Descriptor for `GridSettingChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridSettingChangesetPBDescriptor = $convert.base64Decode('ChZHcmlkU2V0dGluZ0NoYW5nZXNldFBCEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIsCgtsYXlvdXRfdHlwZRgCIAEoDjILLkdyaWRMYXlvdXRSCmxheW91dFR5cGUSOgoMYWx0ZXJfZmlsdGVyGAMgASgLMhUuQWx0ZXJGaWx0ZXJQYXlsb2FkUEJIAFILYWx0ZXJGaWx0ZXISPQoNZGVsZXRlX2ZpbHRlchgEIAEoCzIWLkRlbGV0ZUZpbHRlclBheWxvYWRQQkgBUgxkZWxldGVGaWx0ZXISOgoMaW5zZXJ0X2dyb3VwGAUgASgLMhUuSW5zZXJ0R3JvdXBQYXlsb2FkUEJIAlILaW5zZXJ0R3JvdXASOgoMZGVsZXRlX2dyb3VwGAYgASgLMhUuRGVsZXRlR3JvdXBQYXlsb2FkUEJIA1ILZGVsZXRlR3JvdXASNAoKYWx0ZXJfc29ydBgHIAEoCzITLkFsdGVyU29ydFBheWxvYWRQQkgEUglhbHRlclNvcnQSNwoLZGVsZXRlX3NvcnQYCCABKAsyFC5EZWxldGVTb3J0UGF5bG9hZFBCSAVSCmRlbGV0ZVNvcnRCFQoTb25lX29mX2FsdGVyX2ZpbHRlckIWChRvbmVfb2ZfZGVsZXRlX2ZpbHRlckIVChNvbmVfb2ZfaW5zZXJ0X2dyb3VwQhUKE29uZV9vZl9kZWxldGVfZ3JvdXBCEwoRb25lX29mX2FsdGVyX3NvcnRCFAoSb25lX29mX2RlbGV0ZV9zb3J0');
