///
//  Generated code. Do not modify.
//  source: text_block_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createTextBlockParamsDescriptor instead')
const CreateTextBlockParams$json = const {
  '1': 'CreateTextBlockParams',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'revisions', '3': 2, '4': 1, '5': 11, '6': '.RepeatedRevision', '10': 'revisions'},
  ],
};

/// Descriptor for `CreateTextBlockParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createTextBlockParamsDescriptor = $convert.base64Decode('ChVDcmVhdGVUZXh0QmxvY2tQYXJhbXMSDgoCaWQYASABKAlSAmlkEi8KCXJldmlzaW9ucxgCIAEoCzIRLlJlcGVhdGVkUmV2aXNpb25SCXJldmlzaW9ucw==');
@$core.Deprecated('Use textBlockInfoDescriptor instead')
const TextBlockInfo$json = const {
  '1': 'TextBlockInfo',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    const {'1': 'rev_id', '3': 3, '4': 1, '5': 3, '10': 'revId'},
    const {'1': 'base_rev_id', '3': 4, '4': 1, '5': 3, '10': 'baseRevId'},
  ],
};

/// Descriptor for `TextBlockInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textBlockInfoDescriptor = $convert.base64Decode('Cg1UZXh0QmxvY2tJbmZvEhkKCGJsb2NrX2lkGAEgASgJUgdibG9ja0lkEhIKBHRleHQYAiABKAlSBHRleHQSFQoGcmV2X2lkGAMgASgDUgVyZXZJZBIeCgtiYXNlX3Jldl9pZBgEIAEoA1IJYmFzZVJldklk');
@$core.Deprecated('Use resetTextBlockParamsDescriptor instead')
const ResetTextBlockParams$json = const {
  '1': 'ResetTextBlockParams',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'revisions', '3': 2, '4': 1, '5': 11, '6': '.RepeatedRevision', '10': 'revisions'},
  ],
};

/// Descriptor for `ResetTextBlockParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetTextBlockParamsDescriptor = $convert.base64Decode('ChRSZXNldFRleHRCbG9ja1BhcmFtcxIZCghibG9ja19pZBgBIAEoCVIHYmxvY2tJZBIvCglyZXZpc2lvbnMYAiABKAsyES5SZXBlYXRlZFJldmlzaW9uUglyZXZpc2lvbnM=');
@$core.Deprecated('Use textBlockDeltaDescriptor instead')
const TextBlockDelta$json = const {
  '1': 'TextBlockDelta',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'delta_str', '3': 2, '4': 1, '5': 9, '10': 'deltaStr'},
  ],
};

/// Descriptor for `TextBlockDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textBlockDeltaDescriptor = $convert.base64Decode('Cg5UZXh0QmxvY2tEZWx0YRIZCghibG9ja19pZBgBIAEoCVIHYmxvY2tJZBIbCglkZWx0YV9zdHIYAiABKAlSCGRlbHRhU3Ry');
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
@$core.Deprecated('Use textBlockIdDescriptor instead')
const TextBlockId$json = const {
  '1': 'TextBlockId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `TextBlockId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textBlockIdDescriptor = $convert.base64Decode('CgtUZXh0QmxvY2tJZBIUCgV2YWx1ZRgBIAEoCVIFdmFsdWU=');
