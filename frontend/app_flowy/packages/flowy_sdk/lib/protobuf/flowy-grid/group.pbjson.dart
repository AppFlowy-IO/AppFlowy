///
//  Generated code. Do not modify.
//  source: group.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createBoardCardPayloadPBDescriptor instead')
const CreateBoardCardPayloadPB$json = const {
  '1': 'CreateBoardCardPayloadPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'group_id', '3': 2, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'start_row_id', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'startRowId'},
  ],
  '8': const [
    const {'1': 'one_of_start_row_id'},
  ],
};

/// Descriptor for `CreateBoardCardPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createBoardCardPayloadPBDescriptor = $convert.base64Decode('ChhDcmVhdGVCb2FyZENhcmRQYXlsb2FkUEISFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEhkKCGdyb3VwX2lkGAIgASgJUgdncm91cElkEiIKDHN0YXJ0X3Jvd19pZBgDIAEoCUgAUgpzdGFydFJvd0lkQhUKE29uZV9vZl9zdGFydF9yb3dfaWQ=');
@$core.Deprecated('Use groupConfigurationPBDescriptor instead')
const GroupConfigurationPB$json = const {
  '1': 'GroupConfigurationPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
  ],
};

/// Descriptor for `GroupConfigurationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupConfigurationPBDescriptor = $convert.base64Decode('ChRHcm91cENvbmZpZ3VyYXRpb25QQhIOCgJpZBgBIAEoCVICaWQSGQoIZmllbGRfaWQYAiABKAlSB2ZpZWxkSWQ=');
@$core.Deprecated('Use repeatedGroupPBDescriptor instead')
const RepeatedGroupPB$json = const {
  '1': 'RepeatedGroupPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.GroupPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedGroupPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedGroupPBDescriptor = $convert.base64Decode('Cg9SZXBlYXRlZEdyb3VwUEISHgoFaXRlbXMYASADKAsyCC5Hcm91cFBCUgVpdGVtcw==');
@$core.Deprecated('Use groupPBDescriptor instead')
const GroupPB$json = const {
  '1': 'GroupPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'group_id', '3': 2, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'rows', '3': 4, '4': 3, '5': 11, '6': '.RowPB', '10': 'rows'},
    const {'1': 'is_default', '3': 5, '4': 1, '5': 8, '10': 'isDefault'},
    const {'1': 'is_visible', '3': 6, '4': 1, '5': 8, '10': 'isVisible'},
  ],
};

/// Descriptor for `GroupPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupPBDescriptor = $convert.base64Decode('CgdHcm91cFBCEhkKCGZpZWxkX2lkGAEgASgJUgdmaWVsZElkEhkKCGdyb3VwX2lkGAIgASgJUgdncm91cElkEhIKBGRlc2MYAyABKAlSBGRlc2MSGgoEcm93cxgEIAMoCzIGLlJvd1BCUgRyb3dzEh0KCmlzX2RlZmF1bHQYBSABKAhSCWlzRGVmYXVsdBIdCgppc192aXNpYmxlGAYgASgIUglpc1Zpc2libGU=');
@$core.Deprecated('Use repeatedGroupConfigurationPBDescriptor instead')
const RepeatedGroupConfigurationPB$json = const {
  '1': 'RepeatedGroupConfigurationPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.GroupConfigurationPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedGroupConfigurationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedGroupConfigurationPBDescriptor = $convert.base64Decode('ChxSZXBlYXRlZEdyb3VwQ29uZmlndXJhdGlvblBCEisKBWl0ZW1zGAEgAygLMhUuR3JvdXBDb25maWd1cmF0aW9uUEJSBWl0ZW1z');
@$core.Deprecated('Use insertGroupPayloadPBDescriptor instead')
const InsertGroupPayloadPB$json = const {
  '1': 'InsertGroupPayloadPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 2, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
  ],
};

/// Descriptor for `InsertGroupPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List insertGroupPayloadPBDescriptor = $convert.base64Decode('ChRJbnNlcnRHcm91cFBheWxvYWRQQhIZCghmaWVsZF9pZBgBIAEoCVIHZmllbGRJZBIpCgpmaWVsZF90eXBlGAIgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGU=');
@$core.Deprecated('Use deleteGroupPayloadPBDescriptor instead')
const DeleteGroupPayloadPB$json = const {
  '1': 'DeleteGroupPayloadPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'group_id', '3': 2, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
  ],
};

/// Descriptor for `DeleteGroupPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteGroupPayloadPBDescriptor = $convert.base64Decode('ChREZWxldGVHcm91cFBheWxvYWRQQhIZCghmaWVsZF9pZBgBIAEoCVIHZmllbGRJZBIZCghncm91cF9pZBgCIAEoCVIHZ3JvdXBJZBIpCgpmaWVsZF90eXBlGAMgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGU=');
