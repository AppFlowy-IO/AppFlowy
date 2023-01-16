///
//  Generated code. Do not modify.
//  source: view.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use viewDataFormatPBDescriptor instead')
const ViewDataFormatPB$json = const {
  '1': 'ViewDataFormatPB',
  '2': const [
    const {'1': 'DeltaFormat', '2': 0},
    const {'1': 'DatabaseFormat', '2': 1},
    const {'1': 'TreeFormat', '2': 2},
  ],
};

/// Descriptor for `ViewDataFormatPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List viewDataFormatPBDescriptor = $convert.base64Decode('ChBWaWV3RGF0YUZvcm1hdFBCEg8KC0RlbHRhRm9ybWF0EAASEgoORGF0YWJhc2VGb3JtYXQQARIOCgpUcmVlRm9ybWF0EAI=');
@$core.Deprecated('Use viewLayoutTypePBDescriptor instead')
const ViewLayoutTypePB$json = const {
  '1': 'ViewLayoutTypePB',
  '2': const [
    const {'1': 'Document', '2': 0},
    const {'1': 'Grid', '2': 3},
    const {'1': 'Board', '2': 4},
  ],
};

/// Descriptor for `ViewLayoutTypePB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List viewLayoutTypePBDescriptor = $convert.base64Decode('ChBWaWV3TGF5b3V0VHlwZVBCEgwKCERvY3VtZW50EAASCAoER3JpZBADEgkKBUJvYXJkEAQ=');
@$core.Deprecated('Use moveFolderItemTypeDescriptor instead')
const MoveFolderItemType$json = const {
  '1': 'MoveFolderItemType',
  '2': const [
    const {'1': 'MoveApp', '2': 0},
    const {'1': 'MoveView', '2': 1},
  ],
};

/// Descriptor for `MoveFolderItemType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List moveFolderItemTypeDescriptor = $convert.base64Decode('ChJNb3ZlRm9sZGVySXRlbVR5cGUSCwoHTW92ZUFwcBAAEgwKCE1vdmVWaWV3EAE=');
@$core.Deprecated('Use viewPBDescriptor instead')
const ViewPB$json = const {
  '1': 'ViewPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'app_id', '3': 2, '4': 1, '5': 9, '10': 'appId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'data_format', '3': 4, '4': 1, '5': 14, '6': '.ViewDataFormatPB', '10': 'dataFormat'},
    const {'1': 'modified_time', '3': 5, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'create_time', '3': 6, '4': 1, '5': 3, '10': 'createTime'},
    const {'1': 'layout', '3': 7, '4': 1, '5': 14, '6': '.ViewLayoutTypePB', '10': 'layout'},
  ],
};

/// Descriptor for `ViewPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewPBDescriptor = $convert.base64Decode('CgZWaWV3UEISDgoCaWQYASABKAlSAmlkEhUKBmFwcF9pZBgCIAEoCVIFYXBwSWQSEgoEbmFtZRgDIAEoCVIEbmFtZRIyCgtkYXRhX2Zvcm1hdBgEIAEoDjIRLlZpZXdEYXRhRm9ybWF0UEJSCmRhdGFGb3JtYXQSIwoNbW9kaWZpZWRfdGltZRgFIAEoA1IMbW9kaWZpZWRUaW1lEh8KC2NyZWF0ZV90aW1lGAYgASgDUgpjcmVhdGVUaW1lEikKBmxheW91dBgHIAEoDjIRLlZpZXdMYXlvdXRUeXBlUEJSBmxheW91dA==');
@$core.Deprecated('Use repeatedViewPBDescriptor instead')
const RepeatedViewPB$json = const {
  '1': 'RepeatedViewPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.ViewPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedViewPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedViewPBDescriptor = $convert.base64Decode('Cg5SZXBlYXRlZFZpZXdQQhIdCgVpdGVtcxgBIAMoCzIHLlZpZXdQQlIFaXRlbXM=');
@$core.Deprecated('Use repeatedViewIdPBDescriptor instead')
const RepeatedViewIdPB$json = const {
  '1': 'RepeatedViewIdPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 9, '10': 'items'},
  ],
};

/// Descriptor for `RepeatedViewIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedViewIdPBDescriptor = $convert.base64Decode('ChBSZXBlYXRlZFZpZXdJZFBCEhQKBWl0ZW1zGAEgAygJUgVpdGVtcw==');
@$core.Deprecated('Use createViewPayloadPBDescriptor instead')
const CreateViewPayloadPB$json = const {
  '1': 'CreateViewPayloadPB',
  '2': const [
    const {'1': 'belong_to_id', '3': 1, '4': 1, '5': 9, '10': 'belongToId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'thumbnail', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'thumbnail'},
    const {'1': 'data_format', '3': 5, '4': 1, '5': 14, '6': '.ViewDataFormatPB', '10': 'dataFormat'},
    const {'1': 'layout', '3': 6, '4': 1, '5': 14, '6': '.ViewLayoutTypePB', '10': 'layout'},
    const {'1': 'view_content_data', '3': 7, '4': 1, '5': 12, '10': 'viewContentData'},
  ],
  '8': const [
    const {'1': 'one_of_thumbnail'},
  ],
};

/// Descriptor for `CreateViewPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createViewPayloadPBDescriptor = $convert.base64Decode('ChNDcmVhdGVWaWV3UGF5bG9hZFBCEiAKDGJlbG9uZ190b19pZBgBIAEoCVIKYmVsb25nVG9JZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2MSHgoJdGh1bWJuYWlsGAQgASgJSABSCXRodW1ibmFpbBIyCgtkYXRhX2Zvcm1hdBgFIAEoDjIRLlZpZXdEYXRhRm9ybWF0UEJSCmRhdGFGb3JtYXQSKQoGbGF5b3V0GAYgASgOMhEuVmlld0xheW91dFR5cGVQQlIGbGF5b3V0EioKEXZpZXdfY29udGVudF9kYXRhGAcgASgMUg92aWV3Q29udGVudERhdGFCEgoQb25lX29mX3RodW1ibmFpbA==');
@$core.Deprecated('Use viewIdPBDescriptor instead')
const ViewIdPB$json = const {
  '1': 'ViewIdPB',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `ViewIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewIdPBDescriptor = $convert.base64Decode('CghWaWV3SWRQQhIUCgV2YWx1ZRgBIAEoCVIFdmFsdWU=');
@$core.Deprecated('Use deletedViewPBDescriptor instead')
const DeletedViewPB$json = const {
  '1': 'DeletedViewPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'index', '3': 2, '4': 1, '5': 5, '9': 0, '10': 'index'},
  ],
  '8': const [
    const {'1': 'one_of_index'},
  ],
};

/// Descriptor for `DeletedViewPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletedViewPBDescriptor = $convert.base64Decode('Cg1EZWxldGVkVmlld1BCEhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBIWCgVpbmRleBgCIAEoBUgAUgVpbmRleEIOCgxvbmVfb2ZfaW5kZXg=');
@$core.Deprecated('Use updateViewPayloadPBDescriptor instead')
const UpdateViewPayloadPB$json = const {
  '1': 'UpdateViewPayloadPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'thumbnail', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'thumbnail'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_thumbnail'},
  ],
};

/// Descriptor for `UpdateViewPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateViewPayloadPBDescriptor = $convert.base64Decode('ChNVcGRhdGVWaWV3UGF5bG9hZFBCEhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBIUCgRuYW1lGAIgASgJSABSBG5hbWUSFAoEZGVzYxgDIAEoCUgBUgRkZXNjEh4KCXRodW1ibmFpbBgEIAEoCUgCUgl0aHVtYm5haWxCDQoLb25lX29mX25hbWVCDQoLb25lX29mX2Rlc2NCEgoQb25lX29mX3RodW1ibmFpbA==');
@$core.Deprecated('Use moveFolderItemPayloadPBDescriptor instead')
const MoveFolderItemPayloadPB$json = const {
  '1': 'MoveFolderItemPayloadPB',
  '2': const [
    const {'1': 'item_id', '3': 1, '4': 1, '5': 9, '10': 'itemId'},
    const {'1': 'from', '3': 2, '4': 1, '5': 5, '10': 'from'},
    const {'1': 'to', '3': 3, '4': 1, '5': 5, '10': 'to'},
    const {'1': 'ty', '3': 4, '4': 1, '5': 14, '6': '.MoveFolderItemType', '10': 'ty'},
  ],
};

/// Descriptor for `MoveFolderItemPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveFolderItemPayloadPBDescriptor = $convert.base64Decode('ChdNb3ZlRm9sZGVySXRlbVBheWxvYWRQQhIXCgdpdGVtX2lkGAEgASgJUgZpdGVtSWQSEgoEZnJvbRgCIAEoBVIEZnJvbRIOCgJ0bxgDIAEoBVICdG8SIwoCdHkYBCABKA4yEy5Nb3ZlRm9sZGVySXRlbVR5cGVSAnR5');
