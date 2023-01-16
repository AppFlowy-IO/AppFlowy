///
//  Generated code. Do not modify.
//  source: sort_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use gridSortConditionPBDescriptor instead')
const GridSortConditionPB$json = const {
  '1': 'GridSortConditionPB',
  '2': const [
    const {'1': 'Ascending', '2': 0},
    const {'1': 'Descending', '2': 1},
  ],
};

/// Descriptor for `GridSortConditionPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gridSortConditionPBDescriptor = $convert.base64Decode('ChNHcmlkU29ydENvbmRpdGlvblBCEg0KCUFzY2VuZGluZxAAEg4KCkRlc2NlbmRpbmcQAQ==');
@$core.Deprecated('Use gridSortPBDescriptor instead')
const GridSortPB$json = const {
  '1': 'GridSortPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'condition', '3': 4, '4': 1, '5': 14, '6': '.GridSortConditionPB', '10': 'condition'},
  ],
};

/// Descriptor for `GridSortPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridSortPBDescriptor = $convert.base64Decode('CgpHcmlkU29ydFBCEg4KAmlkGAEgASgJUgJpZBIZCghmaWVsZF9pZBgCIAEoCVIHZmllbGRJZBIpCgpmaWVsZF90eXBlGAMgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGUSMgoJY29uZGl0aW9uGAQgASgOMhQuR3JpZFNvcnRDb25kaXRpb25QQlIJY29uZGl0aW9u');
@$core.Deprecated('Use alterSortPayloadPBDescriptor instead')
const AlterSortPayloadPB$json = const {
  '1': 'AlterSortPayloadPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'sort_id', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'sortId'},
    const {'1': 'condition', '3': 5, '4': 1, '5': 14, '6': '.GridSortConditionPB', '10': 'condition'},
  ],
  '8': const [
    const {'1': 'one_of_sort_id'},
  ],
};

/// Descriptor for `AlterSortPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List alterSortPayloadPBDescriptor = $convert.base64Decode('ChJBbHRlclNvcnRQYXlsb2FkUEISFwoHdmlld19pZBgBIAEoCVIGdmlld0lkEhkKCGZpZWxkX2lkGAIgASgJUgdmaWVsZElkEikKCmZpZWxkX3R5cGUYAyABKA4yCi5GaWVsZFR5cGVSCWZpZWxkVHlwZRIZCgdzb3J0X2lkGAQgASgJSABSBnNvcnRJZBIyCgljb25kaXRpb24YBSABKA4yFC5HcmlkU29ydENvbmRpdGlvblBCUgljb25kaXRpb25CEAoOb25lX29mX3NvcnRfaWQ=');
@$core.Deprecated('Use deleteSortPayloadPBDescriptor instead')
const DeleteSortPayloadPB$json = const {
  '1': 'DeleteSortPayloadPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'sort_id', '3': 4, '4': 1, '5': 9, '10': 'sortId'},
  ],
};

/// Descriptor for `DeleteSortPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSortPayloadPBDescriptor = $convert.base64Decode('ChNEZWxldGVTb3J0UGF5bG9hZFBCEhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBIZCghmaWVsZF9pZBgCIAEoCVIHZmllbGRJZBIpCgpmaWVsZF90eXBlGAMgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGUSFwoHc29ydF9pZBgEIAEoCVIGc29ydElk');
@$core.Deprecated('Use sortChangesetNotificationPBDescriptor instead')
const SortChangesetNotificationPB$json = const {
  '1': 'SortChangesetNotificationPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'insert_sorts', '3': 2, '4': 3, '5': 11, '6': '.GridSortPB', '10': 'insertSorts'},
    const {'1': 'delete_sorts', '3': 3, '4': 3, '5': 11, '6': '.GridSortPB', '10': 'deleteSorts'},
    const {'1': 'update_sorts', '3': 4, '4': 3, '5': 11, '6': '.GridSortPB', '10': 'updateSorts'},
  ],
};

/// Descriptor for `SortChangesetNotificationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sortChangesetNotificationPBDescriptor = $convert.base64Decode('ChtTb3J0Q2hhbmdlc2V0Tm90aWZpY2F0aW9uUEISFwoHdmlld19pZBgBIAEoCVIGdmlld0lkEi4KDGluc2VydF9zb3J0cxgCIAMoCzILLkdyaWRTb3J0UEJSC2luc2VydFNvcnRzEi4KDGRlbGV0ZV9zb3J0cxgDIAMoCzILLkdyaWRTb3J0UEJSC2RlbGV0ZVNvcnRzEi4KDHVwZGF0ZV9zb3J0cxgEIAMoCzILLkdyaWRTb3J0UEJSC3VwZGF0ZVNvcnRz');
@$core.Deprecated('Use reorderAllRowsPBDescriptor instead')
const ReorderAllRowsPB$json = const {
  '1': 'ReorderAllRowsPB',
  '2': const [
    const {'1': 'row_orders', '3': 1, '4': 3, '5': 9, '10': 'rowOrders'},
  ],
};

/// Descriptor for `ReorderAllRowsPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reorderAllRowsPBDescriptor = $convert.base64Decode('ChBSZW9yZGVyQWxsUm93c1BCEh0KCnJvd19vcmRlcnMYASADKAlSCXJvd09yZGVycw==');
@$core.Deprecated('Use reorderSingleRowPBDescriptor instead')
const ReorderSingleRowPB$json = const {
  '1': 'ReorderSingleRowPB',
  '2': const [
    const {'1': 'old_index', '3': 1, '4': 1, '5': 5, '10': 'oldIndex'},
    const {'1': 'new_index', '3': 2, '4': 1, '5': 5, '10': 'newIndex'},
  ],
};

/// Descriptor for `ReorderSingleRowPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reorderSingleRowPBDescriptor = $convert.base64Decode('ChJSZW9yZGVyU2luZ2xlUm93UEISGwoJb2xkX2luZGV4GAEgASgFUghvbGRJbmRleBIbCgluZXdfaW5kZXgYAiABKAVSCG5ld0luZGV4');
