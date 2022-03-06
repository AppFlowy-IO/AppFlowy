///
//  Generated code. Do not modify.
//  source: msg.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use wSChannelDescriptor instead')
const WSChannel$json = const {
  '1': 'WSChannel',
  '2': const [
    const {'1': 'Document', '2': 0},
    const {'1': 'Folder', '2': 1},
    const {'1': 'Grid', '2': 2},
  ],
};

/// Descriptor for `WSChannel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List wSChannelDescriptor = $convert.base64Decode('CglXU0NoYW5uZWwSDAoIRG9jdW1lbnQQABIKCgZGb2xkZXIQARIICgRHcmlkEAI=');
@$core.Deprecated('Use webSocketRawMessageDescriptor instead')
const WebSocketRawMessage$json = const {
  '1': 'WebSocketRawMessage',
  '2': const [
    const {'1': 'channel', '3': 1, '4': 1, '5': 14, '6': '.WSChannel', '10': 'channel'},
    const {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `WebSocketRawMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webSocketRawMessageDescriptor = $convert.base64Decode('ChNXZWJTb2NrZXRSYXdNZXNzYWdlEiQKB2NoYW5uZWwYASABKA4yCi5XU0NoYW5uZWxSB2NoYW5uZWwSEgoEZGF0YRgCIAEoDFIEZGF0YQ==');
