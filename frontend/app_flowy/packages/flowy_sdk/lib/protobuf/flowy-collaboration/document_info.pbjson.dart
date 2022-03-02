///
//  Generated code. Do not modify.
//  source: document_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createBlockParamsDescriptor instead')
const CreateBlockParams$json = const {
  '1': 'CreateBlockParams',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'revisions', '3': 2, '4': 1, '5': 11, '6': '.RepeatedRevision', '10': 'revisions'},
  ],
};

/// Descriptor for `CreateBlockParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createBlockParamsDescriptor = $convert.base64Decode('ChFDcmVhdGVCbG9ja1BhcmFtcxIOCgJpZBgBIAEoCVICaWQSLwoJcmV2aXNpb25zGAIgASgLMhEuUmVwZWF0ZWRSZXZpc2lvblIJcmV2aXNpb25z');
@$core.Deprecated('Use blockInfoDescriptor instead')
const BlockInfo$json = const {
  '1': 'BlockInfo',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    const {'1': 'rev_id', '3': 3, '4': 1, '5': 3, '10': 'revId'},
    const {'1': 'base_rev_id', '3': 4, '4': 1, '5': 3, '10': 'baseRevId'},
  ],
};

/// Descriptor for `BlockInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockInfoDescriptor = $convert.base64Decode('CglCbG9ja0luZm8SGQoIYmxvY2tfaWQYASABKAlSB2Jsb2NrSWQSEgoEdGV4dBgCIAEoCVIEdGV4dBIVCgZyZXZfaWQYAyABKANSBXJldklkEh4KC2Jhc2VfcmV2X2lkGAQgASgDUgliYXNlUmV2SWQ=');
@$core.Deprecated('Use resetBlockParamsDescriptor instead')
const ResetBlockParams$json = const {
  '1': 'ResetBlockParams',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'revisions', '3': 2, '4': 1, '5': 11, '6': '.RepeatedRevision', '10': 'revisions'},
  ],
};

/// Descriptor for `ResetBlockParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetBlockParamsDescriptor = $convert.base64Decode('ChBSZXNldEJsb2NrUGFyYW1zEhkKCGJsb2NrX2lkGAEgASgJUgdibG9ja0lkEi8KCXJldmlzaW9ucxgCIAEoCzIRLlJlcGVhdGVkUmV2aXNpb25SCXJldmlzaW9ucw==');
@$core.Deprecated('Use blockDeltaDescriptor instead')
const BlockDelta$json = const {
  '1': 'BlockDelta',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'delta_json', '3': 2, '4': 1, '5': 9, '10': 'deltaJson'},
  ],
};

/// Descriptor for `BlockDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDeltaDescriptor = $convert.base64Decode('CgpCbG9ja0RlbHRhEhkKCGJsb2NrX2lkGAEgASgJUgdibG9ja0lkEh0KCmRlbHRhX2pzb24YAiABKAlSCWRlbHRhSnNvbg==');
@$core.Deprecated('Use newDocUserDescriptor instead')
const NewDocUser$json = const {
  '1': 'NewDocUser',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'rev_id', '3': 2, '4': 1, '5': 3, '10': 'revId'},
    const {'1': 'doc_id', '3': 3, '4': 1, '5': 9, '10': 'docId'},
  ],
};

/// Descriptor for `NewDocUser`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newDocUserDescriptor = $convert.base64Decode('CgpOZXdEb2NVc2VyEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIVCgZyZXZfaWQYAiABKANSBXJldklkEhUKBmRvY19pZBgDIAEoCVIFZG9jSWQ=');
@$core.Deprecated('Use blockIdDescriptor instead')
const BlockId$json = const {
  '1': 'BlockId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `BlockId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockIdDescriptor = $convert.base64Decode('CgdCbG9ja0lkEhQKBXZhbHVlGAEgASgJUgV2YWx1ZQ==');
