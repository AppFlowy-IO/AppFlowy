///
//  Generated code. Do not modify.
//  source: group_changeset.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use groupRowsNotificationPBDescriptor instead')
const GroupRowsNotificationPB$json = const {
  '1': 'GroupRowsNotificationPB',
  '2': const [
    const {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    const {'1': 'group_name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'groupName'},
    const {'1': 'inserted_rows', '3': 3, '4': 3, '5': 11, '6': '.InsertedRowPB', '10': 'insertedRows'},
    const {'1': 'deleted_rows', '3': 4, '4': 3, '5': 9, '10': 'deletedRows'},
    const {'1': 'updated_rows', '3': 5, '4': 3, '5': 11, '6': '.RowPB', '10': 'updatedRows'},
  ],
  '8': const [
    const {'1': 'one_of_group_name'},
  ],
};

/// Descriptor for `GroupRowsNotificationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupRowsNotificationPBDescriptor = $convert.base64Decode('ChdHcm91cFJvd3NOb3RpZmljYXRpb25QQhIZCghncm91cF9pZBgBIAEoCVIHZ3JvdXBJZBIfCgpncm91cF9uYW1lGAIgASgJSABSCWdyb3VwTmFtZRIzCg1pbnNlcnRlZF9yb3dzGAMgAygLMg4uSW5zZXJ0ZWRSb3dQQlIMaW5zZXJ0ZWRSb3dzEiEKDGRlbGV0ZWRfcm93cxgEIAMoCVILZGVsZXRlZFJvd3MSKQoMdXBkYXRlZF9yb3dzGAUgAygLMgYuUm93UEJSC3VwZGF0ZWRSb3dzQhMKEW9uZV9vZl9ncm91cF9uYW1l');
@$core.Deprecated('Use moveGroupPayloadPBDescriptor instead')
const MoveGroupPayloadPB$json = const {
  '1': 'MoveGroupPayloadPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'from_group_id', '3': 2, '4': 1, '5': 9, '10': 'fromGroupId'},
    const {'1': 'to_group_id', '3': 3, '4': 1, '5': 9, '10': 'toGroupId'},
  ],
};

/// Descriptor for `MoveGroupPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveGroupPayloadPBDescriptor = $convert.base64Decode('ChJNb3ZlR3JvdXBQYXlsb2FkUEISFwoHdmlld19pZBgBIAEoCVIGdmlld0lkEiIKDWZyb21fZ3JvdXBfaWQYAiABKAlSC2Zyb21Hcm91cElkEh4KC3RvX2dyb3VwX2lkGAMgASgJUgl0b0dyb3VwSWQ=');
@$core.Deprecated('Use groupViewChangesetPBDescriptor instead')
const GroupViewChangesetPB$json = const {
  '1': 'GroupViewChangesetPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'inserted_groups', '3': 2, '4': 3, '5': 11, '6': '.InsertedGroupPB', '10': 'insertedGroups'},
    const {'1': 'new_groups', '3': 3, '4': 3, '5': 11, '6': '.GroupPB', '10': 'newGroups'},
    const {'1': 'deleted_groups', '3': 4, '4': 3, '5': 9, '10': 'deletedGroups'},
    const {'1': 'update_groups', '3': 5, '4': 3, '5': 11, '6': '.GroupPB', '10': 'updateGroups'},
  ],
};

/// Descriptor for `GroupViewChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupViewChangesetPBDescriptor = $convert.base64Decode('ChRHcm91cFZpZXdDaGFuZ2VzZXRQQhIXCgd2aWV3X2lkGAEgASgJUgZ2aWV3SWQSOQoPaW5zZXJ0ZWRfZ3JvdXBzGAIgAygLMhAuSW5zZXJ0ZWRHcm91cFBCUg5pbnNlcnRlZEdyb3VwcxInCgpuZXdfZ3JvdXBzGAMgAygLMgguR3JvdXBQQlIJbmV3R3JvdXBzEiUKDmRlbGV0ZWRfZ3JvdXBzGAQgAygJUg1kZWxldGVkR3JvdXBzEi0KDXVwZGF0ZV9ncm91cHMYBSADKAsyCC5Hcm91cFBCUgx1cGRhdGVHcm91cHM=');
@$core.Deprecated('Use insertedGroupPBDescriptor instead')
const InsertedGroupPB$json = const {
  '1': 'InsertedGroupPB',
  '2': const [
    const {'1': 'group', '3': 1, '4': 1, '5': 11, '6': '.GroupPB', '10': 'group'},
    const {'1': 'index', '3': 2, '4': 1, '5': 5, '10': 'index'},
  ],
};

/// Descriptor for `InsertedGroupPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List insertedGroupPBDescriptor = $convert.base64Decode('Cg9JbnNlcnRlZEdyb3VwUEISHgoFZ3JvdXAYASABKAsyCC5Hcm91cFBCUgVncm91cBIUCgVpbmRleBgCIAEoBVIFaW5kZXg=');
