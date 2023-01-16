///
//  Generated code. Do not modify.
//  source: grid_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use gridPBDescriptor instead')
const GridPB$json = const {
  '1': 'GridPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'fields', '3': 2, '4': 3, '5': 11, '6': '.FieldIdPB', '10': 'fields'},
    const {'1': 'rows', '3': 3, '4': 3, '5': 11, '6': '.RowPB', '10': 'rows'},
  ],
};

/// Descriptor for `GridPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridPBDescriptor = $convert.base64Decode('CgZHcmlkUEISDgoCaWQYASABKAlSAmlkEiIKBmZpZWxkcxgCIAMoCzIKLkZpZWxkSWRQQlIGZmllbGRzEhoKBHJvd3MYAyADKAsyBi5Sb3dQQlIEcm93cw==');
@$core.Deprecated('Use createGridPayloadPBDescriptor instead')
const CreateGridPayloadPB$json = const {
  '1': 'CreateGridPayloadPB',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `CreateGridPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createGridPayloadPBDescriptor = $convert.base64Decode('ChNDcmVhdGVHcmlkUGF5bG9hZFBCEhIKBG5hbWUYASABKAlSBG5hbWU=');
@$core.Deprecated('Use gridIdPBDescriptor instead')
const GridIdPB$json = const {
  '1': 'GridIdPB',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `GridIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridIdPBDescriptor = $convert.base64Decode('CghHcmlkSWRQQhIUCgV2YWx1ZRgBIAEoCVIFdmFsdWU=');
@$core.Deprecated('Use gridBlockIdPBDescriptor instead')
const GridBlockIdPB$json = const {
  '1': 'GridBlockIdPB',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `GridBlockIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridBlockIdPBDescriptor = $convert.base64Decode('Cg1HcmlkQmxvY2tJZFBCEhQKBXZhbHVlGAEgASgJUgV2YWx1ZQ==');
@$core.Deprecated('Use moveFieldPayloadPBDescriptor instead')
const MoveFieldPayloadPB$json = const {
  '1': 'MoveFieldPayloadPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'from_index', '3': 3, '4': 1, '5': 5, '10': 'fromIndex'},
    const {'1': 'to_index', '3': 4, '4': 1, '5': 5, '10': 'toIndex'},
  ],
};

/// Descriptor for `MoveFieldPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveFieldPayloadPBDescriptor = $convert.base64Decode('ChJNb3ZlRmllbGRQYXlsb2FkUEISFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEhkKCGZpZWxkX2lkGAIgASgJUgdmaWVsZElkEh0KCmZyb21faW5kZXgYAyABKAVSCWZyb21JbmRleBIZCgh0b19pbmRleBgEIAEoBVIHdG9JbmRleA==');
@$core.Deprecated('Use moveRowPayloadPBDescriptor instead')
const MoveRowPayloadPB$json = const {
  '1': 'MoveRowPayloadPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'from_row_id', '3': 2, '4': 1, '5': 9, '10': 'fromRowId'},
    const {'1': 'to_row_id', '3': 4, '4': 1, '5': 9, '10': 'toRowId'},
  ],
};

/// Descriptor for `MoveRowPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveRowPayloadPBDescriptor = $convert.base64Decode('ChBNb3ZlUm93UGF5bG9hZFBCEhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBIeCgtmcm9tX3Jvd19pZBgCIAEoCVIJZnJvbVJvd0lkEhoKCXRvX3Jvd19pZBgEIAEoCVIHdG9Sb3dJZA==');
@$core.Deprecated('Use moveGroupRowPayloadPBDescriptor instead')
const MoveGroupRowPayloadPB$json = const {
  '1': 'MoveGroupRowPayloadPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'from_row_id', '3': 2, '4': 1, '5': 9, '10': 'fromRowId'},
    const {'1': 'to_group_id', '3': 3, '4': 1, '5': 9, '10': 'toGroupId'},
    const {'1': 'to_row_id', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'toRowId'},
  ],
  '8': const [
    const {'1': 'one_of_to_row_id'},
  ],
};

/// Descriptor for `MoveGroupRowPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveGroupRowPayloadPBDescriptor = $convert.base64Decode('ChVNb3ZlR3JvdXBSb3dQYXlsb2FkUEISFwoHdmlld19pZBgBIAEoCVIGdmlld0lkEh4KC2Zyb21fcm93X2lkGAIgASgJUglmcm9tUm93SWQSHgoLdG9fZ3JvdXBfaWQYAyABKAlSCXRvR3JvdXBJZBIcCgl0b19yb3dfaWQYBCABKAlIAFIHdG9Sb3dJZEISChBvbmVfb2ZfdG9fcm93X2lk');
