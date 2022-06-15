///
//  Generated code. Do not modify.
//  source: view_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use viewInfoDescriptor instead')
const ViewInfo$json = const {
  '1': 'ViewInfo',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'belong_to_id', '3': 2, '4': 1, '5': 9, '10': 'belongToId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'data_type', '3': 5, '4': 1, '5': 14, '6': '.ViewDataType', '10': 'dataType'},
    const {'1': 'belongings', '3': 6, '4': 1, '5': 11, '6': '.RepeatedView', '10': 'belongings'},
    const {'1': 'ext_data', '3': 7, '4': 1, '5': 11, '6': '.ViewExtData', '10': 'extData'},
  ],
};

/// Descriptor for `ViewInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewInfoDescriptor = $convert.base64Decode('CghWaWV3SW5mbxIOCgJpZBgBIAEoCVICaWQSIAoMYmVsb25nX3RvX2lkGAIgASgJUgpiZWxvbmdUb0lkEhIKBG5hbWUYAyABKAlSBG5hbWUSEgoEZGVzYxgEIAEoCVIEZGVzYxIqCglkYXRhX3R5cGUYBSABKA4yDS5WaWV3RGF0YVR5cGVSCGRhdGFUeXBlEi0KCmJlbG9uZ2luZ3MYBiABKAsyDS5SZXBlYXRlZFZpZXdSCmJlbG9uZ2luZ3MSJwoIZXh0X2RhdGEYByABKAsyDC5WaWV3RXh0RGF0YVIHZXh0RGF0YQ==');
@$core.Deprecated('Use viewExtDataDescriptor instead')
const ViewExtData$json = const {
  '1': 'ViewExtData',
  '2': const [
    const {'1': 'filter', '3': 1, '4': 1, '5': 11, '6': '.ViewFilter', '10': 'filter'},
    const {'1': 'group', '3': 2, '4': 1, '5': 11, '6': '.ViewGroup', '10': 'group'},
    const {'1': 'sort', '3': 3, '4': 1, '5': 11, '6': '.ViewSort', '10': 'sort'},
  ],
};

/// Descriptor for `ViewExtData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewExtDataDescriptor = $convert.base64Decode('CgtWaWV3RXh0RGF0YRIjCgZmaWx0ZXIYASABKAsyCy5WaWV3RmlsdGVyUgZmaWx0ZXISIAoFZ3JvdXAYAiABKAsyCi5WaWV3R3JvdXBSBWdyb3VwEh0KBHNvcnQYAyABKAsyCS5WaWV3U29ydFIEc29ydA==');
@$core.Deprecated('Use viewFilterDescriptor instead')
const ViewFilter$json = const {
  '1': 'ViewFilter',
  '2': const [
    const {'1': 'object_id', '3': 1, '4': 1, '5': 9, '10': 'objectId'},
  ],
};

/// Descriptor for `ViewFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewFilterDescriptor = $convert.base64Decode('CgpWaWV3RmlsdGVyEhsKCW9iamVjdF9pZBgBIAEoCVIIb2JqZWN0SWQ=');
@$core.Deprecated('Use viewGroupDescriptor instead')
const ViewGroup$json = const {
  '1': 'ViewGroup',
  '2': const [
    const {'1': 'group_object_id', '3': 1, '4': 1, '5': 9, '10': 'groupObjectId'},
    const {'1': 'sub_group_object_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'subGroupObjectId'},
  ],
  '8': const [
    const {'1': 'one_of_sub_group_object_id'},
  ],
};

/// Descriptor for `ViewGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewGroupDescriptor = $convert.base64Decode('CglWaWV3R3JvdXASJgoPZ3JvdXBfb2JqZWN0X2lkGAEgASgJUg1ncm91cE9iamVjdElkEi8KE3N1Yl9ncm91cF9vYmplY3RfaWQYAiABKAlIAFIQc3ViR3JvdXBPYmplY3RJZEIcChpvbmVfb2Zfc3ViX2dyb3VwX29iamVjdF9pZA==');
@$core.Deprecated('Use viewSortDescriptor instead')
const ViewSort$json = const {
  '1': 'ViewSort',
  '2': const [
    const {'1': 'object_id', '3': 1, '4': 1, '5': 9, '10': 'objectId'},
  ],
};

/// Descriptor for `ViewSort`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewSortDescriptor = $convert.base64Decode('CghWaWV3U29ydBIbCglvYmplY3RfaWQYASABKAlSCG9iamVjdElk');
@$core.Deprecated('Use updateViewInfoPayloadDescriptor instead')
const UpdateViewInfoPayload$json = const {
  '1': 'UpdateViewInfoPayload',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'filter', '3': 2, '4': 1, '5': 11, '6': '.ViewFilter', '9': 0, '10': 'filter'},
    const {'1': 'group', '3': 3, '4': 1, '5': 11, '6': '.ViewGroup', '9': 1, '10': 'group'},
    const {'1': 'sort', '3': 4, '4': 1, '5': 11, '6': '.ViewSort', '9': 2, '10': 'sort'},
  ],
  '8': const [
    const {'1': 'one_of_filter'},
    const {'1': 'one_of_group'},
    const {'1': 'one_of_sort'},
  ],
};

/// Descriptor for `UpdateViewInfoPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateViewInfoPayloadDescriptor = $convert.base64Decode('ChVVcGRhdGVWaWV3SW5mb1BheWxvYWQSFwoHdmlld19pZBgBIAEoCVIGdmlld0lkEiUKBmZpbHRlchgCIAEoCzILLlZpZXdGaWx0ZXJIAFIGZmlsdGVyEiIKBWdyb3VwGAMgASgLMgouVmlld0dyb3VwSAFSBWdyb3VwEh8KBHNvcnQYBCABKAsyCS5WaWV3U29ydEgCUgRzb3J0Qg8KDW9uZV9vZl9maWx0ZXJCDgoMb25lX29mX2dyb3VwQg0KC29uZV9vZl9zb3J0');
