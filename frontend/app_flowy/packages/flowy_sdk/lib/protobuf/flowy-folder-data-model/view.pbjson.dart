///
//  Generated code. Do not modify.
//  source: view.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use viewDataTypeDescriptor instead')
const ViewDataType$json = const {
  '1': 'ViewDataType',
  '2': const [
    const {'1': 'TextBlock', '2': 0},
    const {'1': 'Grid', '2': 1},
  ],
};

/// Descriptor for `ViewDataType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List viewDataTypeDescriptor = $convert.base64Decode('CgxWaWV3RGF0YVR5cGUSDQoJVGV4dEJsb2NrEAASCAoER3JpZBAB');
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
@$core.Deprecated('Use viewDescriptor instead')
const View$json = const {
  '1': 'View',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'belong_to_id', '3': 2, '4': 1, '5': 9, '10': 'belongToId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'data_type', '3': 4, '4': 1, '5': 14, '6': '.ViewDataType', '10': 'dataType'},
    const {'1': 'modified_time', '3': 5, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'create_time', '3': 6, '4': 1, '5': 3, '10': 'createTime'},
    const {'1': 'plugin_type', '3': 7, '4': 1, '5': 5, '10': 'pluginType'},
  ],
};

/// Descriptor for `View`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewDescriptor = $convert.base64Decode('CgRWaWV3Eg4KAmlkGAEgASgJUgJpZBIgCgxiZWxvbmdfdG9faWQYAiABKAlSCmJlbG9uZ1RvSWQSEgoEbmFtZRgDIAEoCVIEbmFtZRIqCglkYXRhX3R5cGUYBCABKA4yDS5WaWV3RGF0YVR5cGVSCGRhdGFUeXBlEiMKDW1vZGlmaWVkX3RpbWUYBSABKANSDG1vZGlmaWVkVGltZRIfCgtjcmVhdGVfdGltZRgGIAEoA1IKY3JlYXRlVGltZRIfCgtwbHVnaW5fdHlwZRgHIAEoBVIKcGx1Z2luVHlwZQ==');
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
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
  ],
};

/// Descriptor for `ViewFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewFilterDescriptor = $convert.base64Decode('CgpWaWV3RmlsdGVyEhkKCGZpZWxkX2lkGAEgASgJUgdmaWVsZElk');
@$core.Deprecated('Use viewGroupDescriptor instead')
const ViewGroup$json = const {
  '1': 'ViewGroup',
  '2': const [
    const {'1': 'group_field_id', '3': 1, '4': 1, '5': 9, '10': 'groupFieldId'},
    const {'1': 'sub_group_field_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'subGroupFieldId'},
  ],
  '8': const [
    const {'1': 'one_of_sub_group_field_id'},
  ],
};

/// Descriptor for `ViewGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewGroupDescriptor = $convert.base64Decode('CglWaWV3R3JvdXASJAoOZ3JvdXBfZmllbGRfaWQYASABKAlSDGdyb3VwRmllbGRJZBItChJzdWJfZ3JvdXBfZmllbGRfaWQYAiABKAlIAFIPc3ViR3JvdXBGaWVsZElkQhsKGW9uZV9vZl9zdWJfZ3JvdXBfZmllbGRfaWQ=');
@$core.Deprecated('Use viewSortDescriptor instead')
const ViewSort$json = const {
  '1': 'ViewSort',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
  ],
};

/// Descriptor for `ViewSort`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewSortDescriptor = $convert.base64Decode('CghWaWV3U29ydBIZCghmaWVsZF9pZBgBIAEoCVIHZmllbGRJZA==');
@$core.Deprecated('Use repeatedViewDescriptor instead')
const RepeatedView$json = const {
  '1': 'RepeatedView',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.View', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedView`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedViewDescriptor = $convert.base64Decode('CgxSZXBlYXRlZFZpZXcSGwoFaXRlbXMYASADKAsyBS5WaWV3UgVpdGVtcw==');
@$core.Deprecated('Use createViewPayloadDescriptor instead')
const CreateViewPayload$json = const {
  '1': 'CreateViewPayload',
  '2': const [
    const {'1': 'belong_to_id', '3': 1, '4': 1, '5': 9, '10': 'belongToId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'thumbnail', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'thumbnail'},
    const {'1': 'data_type', '3': 5, '4': 1, '5': 14, '6': '.ViewDataType', '10': 'dataType'},
    const {'1': 'plugin_type', '3': 6, '4': 1, '5': 5, '10': 'pluginType'},
    const {'1': 'data', '3': 7, '4': 1, '5': 12, '10': 'data'},
  ],
  '8': const [
    const {'1': 'one_of_thumbnail'},
  ],
};

/// Descriptor for `CreateViewPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createViewPayloadDescriptor = $convert.base64Decode('ChFDcmVhdGVWaWV3UGF5bG9hZBIgCgxiZWxvbmdfdG9faWQYASABKAlSCmJlbG9uZ1RvSWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEh4KCXRodW1ibmFpbBgEIAEoCUgAUgl0aHVtYm5haWwSKgoJZGF0YV90eXBlGAUgASgOMg0uVmlld0RhdGFUeXBlUghkYXRhVHlwZRIfCgtwbHVnaW5fdHlwZRgGIAEoBVIKcGx1Z2luVHlwZRISCgRkYXRhGAcgASgMUgRkYXRhQhIKEG9uZV9vZl90aHVtYm5haWw=');
@$core.Deprecated('Use createViewParamsDescriptor instead')
const CreateViewParams$json = const {
  '1': 'CreateViewParams',
  '2': const [
    const {'1': 'belong_to_id', '3': 1, '4': 1, '5': 9, '10': 'belongToId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'thumbnail', '3': 4, '4': 1, '5': 9, '10': 'thumbnail'},
    const {'1': 'data_type', '3': 5, '4': 1, '5': 14, '6': '.ViewDataType', '10': 'dataType'},
    const {'1': 'view_id', '3': 6, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'data', '3': 7, '4': 1, '5': 12, '10': 'data'},
    const {'1': 'plugin_type', '3': 8, '4': 1, '5': 5, '10': 'pluginType'},
  ],
};

/// Descriptor for `CreateViewParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createViewParamsDescriptor = $convert.base64Decode('ChBDcmVhdGVWaWV3UGFyYW1zEiAKDGJlbG9uZ190b19pZBgBIAEoCVIKYmVsb25nVG9JZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2MSHAoJdGh1bWJuYWlsGAQgASgJUgl0aHVtYm5haWwSKgoJZGF0YV90eXBlGAUgASgOMg0uVmlld0RhdGFUeXBlUghkYXRhVHlwZRIXCgd2aWV3X2lkGAYgASgJUgZ2aWV3SWQSEgoEZGF0YRgHIAEoDFIEZGF0YRIfCgtwbHVnaW5fdHlwZRgIIAEoBVIKcGx1Z2luVHlwZQ==');
@$core.Deprecated('Use viewIdDescriptor instead')
const ViewId$json = const {
  '1': 'ViewId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `ViewId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewIdDescriptor = $convert.base64Decode('CgZWaWV3SWQSFAoFdmFsdWUYASABKAlSBXZhbHVl');
@$core.Deprecated('Use repeatedViewIdDescriptor instead')
const RepeatedViewId$json = const {
  '1': 'RepeatedViewId',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 9, '10': 'items'},
  ],
};

/// Descriptor for `RepeatedViewId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedViewIdDescriptor = $convert.base64Decode('Cg5SZXBlYXRlZFZpZXdJZBIUCgVpdGVtcxgBIAMoCVIFaXRlbXM=');
@$core.Deprecated('Use updateViewPayloadDescriptor instead')
const UpdateViewPayload$json = const {
  '1': 'UpdateViewPayload',
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

/// Descriptor for `UpdateViewPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateViewPayloadDescriptor = $convert.base64Decode('ChFVcGRhdGVWaWV3UGF5bG9hZBIXCgd2aWV3X2lkGAEgASgJUgZ2aWV3SWQSFAoEbmFtZRgCIAEoCUgAUgRuYW1lEhQKBGRlc2MYAyABKAlIAVIEZGVzYxIeCgl0aHVtYm5haWwYBCABKAlIAlIJdGh1bWJuYWlsQg0KC29uZV9vZl9uYW1lQg0KC29uZV9vZl9kZXNjQhIKEG9uZV9vZl90aHVtYm5haWw=');
@$core.Deprecated('Use updateViewParamsDescriptor instead')
const UpdateViewParams$json = const {
  '1': 'UpdateViewParams',
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

/// Descriptor for `UpdateViewParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateViewParamsDescriptor = $convert.base64Decode('ChBVcGRhdGVWaWV3UGFyYW1zEhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBIUCgRuYW1lGAIgASgJSABSBG5hbWUSFAoEZGVzYxgDIAEoCUgBUgRkZXNjEh4KCXRodW1ibmFpbBgEIAEoCUgCUgl0aHVtYm5haWxCDQoLb25lX29mX25hbWVCDQoLb25lX29mX2Rlc2NCEgoQb25lX29mX3RodW1ibmFpbA==');
@$core.Deprecated('Use moveFolderItemPayloadDescriptor instead')
const MoveFolderItemPayload$json = const {
  '1': 'MoveFolderItemPayload',
  '2': const [
    const {'1': 'item_id', '3': 1, '4': 1, '5': 9, '10': 'itemId'},
    const {'1': 'from', '3': 2, '4': 1, '5': 5, '10': 'from'},
    const {'1': 'to', '3': 3, '4': 1, '5': 5, '10': 'to'},
    const {'1': 'ty', '3': 4, '4': 1, '5': 14, '6': '.MoveFolderItemType', '10': 'ty'},
  ],
};

/// Descriptor for `MoveFolderItemPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveFolderItemPayloadDescriptor = $convert.base64Decode('ChVNb3ZlRm9sZGVySXRlbVBheWxvYWQSFwoHaXRlbV9pZBgBIAEoCVIGaXRlbUlkEhIKBGZyb20YAiABKAVSBGZyb20SDgoCdG8YAyABKAVSAnRvEiMKAnR5GAQgASgOMhMuTW92ZUZvbGRlckl0ZW1UeXBlUgJ0eQ==');
