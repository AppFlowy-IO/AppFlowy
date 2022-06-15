///
//  Generated code. Do not modify.
//  source: grid_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
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
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'fieldId'},
  ],
  '8': const [
    const {'1': 'one_of_field_id'},
  ],
};

/// Descriptor for `ViewFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewFilterDescriptor = $convert.base64Decode('CgpWaWV3RmlsdGVyEhsKCGZpZWxkX2lkGAEgASgJSABSB2ZpZWxkSWRCEQoPb25lX29mX2ZpZWxkX2lk');
@$core.Deprecated('Use viewGroupDescriptor instead')
const ViewGroup$json = const {
  '1': 'ViewGroup',
  '2': const [
    const {'1': 'group_field_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'groupFieldId'},
    const {'1': 'sub_group_field_id', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'subGroupFieldId'},
  ],
  '8': const [
    const {'1': 'one_of_group_field_id'},
    const {'1': 'one_of_sub_group_field_id'},
  ],
};

/// Descriptor for `ViewGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewGroupDescriptor = $convert.base64Decode('CglWaWV3R3JvdXASJgoOZ3JvdXBfZmllbGRfaWQYASABKAlIAFIMZ3JvdXBGaWVsZElkEi0KEnN1Yl9ncm91cF9maWVsZF9pZBgCIAEoCUgBUg9zdWJHcm91cEZpZWxkSWRCFwoVb25lX29mX2dyb3VwX2ZpZWxkX2lkQhsKGW9uZV9vZl9zdWJfZ3JvdXBfZmllbGRfaWQ=');
@$core.Deprecated('Use viewSortDescriptor instead')
const ViewSort$json = const {
  '1': 'ViewSort',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'fieldId'},
  ],
  '8': const [
    const {'1': 'one_of_field_id'},
  ],
};

/// Descriptor for `ViewSort`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewSortDescriptor = $convert.base64Decode('CghWaWV3U29ydBIbCghmaWVsZF9pZBgBIAEoCUgAUgdmaWVsZElkQhEKD29uZV9vZl9maWVsZF9pZA==');
@$core.Deprecated('Use gridInfoChangesetPayloadDescriptor instead')
const GridInfoChangesetPayload$json = const {
  '1': 'GridInfoChangesetPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
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

/// Descriptor for `GridInfoChangesetPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridInfoChangesetPayloadDescriptor = $convert.base64Decode('ChhHcmlkSW5mb0NoYW5nZXNldFBheWxvYWQSFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEiUKBmZpbHRlchgCIAEoCzILLlZpZXdGaWx0ZXJIAFIGZmlsdGVyEiIKBWdyb3VwGAMgASgLMgouVmlld0dyb3VwSAFSBWdyb3VwEh8KBHNvcnQYBCABKAsyCS5WaWV3U29ydEgCUgRzb3J0Qg8KDW9uZV9vZl9maWx0ZXJCDgoMb25lX29mX2dyb3VwQg0KC29uZV9vZl9zb3J0');
