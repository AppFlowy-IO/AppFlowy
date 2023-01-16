///
//  Generated code. Do not modify.
//  source: view_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use gridRowsVisibilityChangesetPBDescriptor instead')
const GridRowsVisibilityChangesetPB$json = const {
  '1': 'GridRowsVisibilityChangesetPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'visible_rows', '3': 5, '4': 3, '5': 11, '6': '.InsertedRowPB', '10': 'visibleRows'},
    const {'1': 'invisible_rows', '3': 6, '4': 3, '5': 9, '10': 'invisibleRows'},
  ],
};

/// Descriptor for `GridRowsVisibilityChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridRowsVisibilityChangesetPBDescriptor = $convert.base64Decode('Ch1HcmlkUm93c1Zpc2liaWxpdHlDaGFuZ2VzZXRQQhIXCgd2aWV3X2lkGAEgASgJUgZ2aWV3SWQSMQoMdmlzaWJsZV9yb3dzGAUgAygLMg4uSW5zZXJ0ZWRSb3dQQlILdmlzaWJsZVJvd3MSJQoOaW52aXNpYmxlX3Jvd3MYBiADKAlSDWludmlzaWJsZVJvd3M=');
@$core.Deprecated('Use gridViewRowsChangesetPBDescriptor instead')
const GridViewRowsChangesetPB$json = const {
  '1': 'GridViewRowsChangesetPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'inserted_rows', '3': 2, '4': 3, '5': 11, '6': '.InsertedRowPB', '10': 'insertedRows'},
    const {'1': 'deleted_rows', '3': 3, '4': 3, '5': 9, '10': 'deletedRows'},
    const {'1': 'updated_rows', '3': 4, '4': 3, '5': 11, '6': '.UpdatedRowPB', '10': 'updatedRows'},
  ],
};

/// Descriptor for `GridViewRowsChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridViewRowsChangesetPBDescriptor = $convert.base64Decode('ChdHcmlkVmlld1Jvd3NDaGFuZ2VzZXRQQhIXCgd2aWV3X2lkGAEgASgJUgZ2aWV3SWQSMwoNaW5zZXJ0ZWRfcm93cxgCIAMoCzIOLkluc2VydGVkUm93UEJSDGluc2VydGVkUm93cxIhCgxkZWxldGVkX3Jvd3MYAyADKAlSC2RlbGV0ZWRSb3dzEjAKDHVwZGF0ZWRfcm93cxgEIAMoCzINLlVwZGF0ZWRSb3dQQlILdXBkYXRlZFJvd3M=');
