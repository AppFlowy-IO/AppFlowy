///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use gridEventDescriptor instead')
const GridEvent$json = const {
  '1': 'GridEvent',
  '2': const [
    const {'1': 'GetGridData', '2': 0},
    const {'1': 'GetRows', '2': 1},
    const {'1': 'GetFields', '2': 2},
    const {'1': 'CreateRow', '2': 3},
    const {'1': 'UpdateCell', '2': 4},
  ],
};

/// Descriptor for `GridEvent`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gridEventDescriptor = $convert.base64Decode('CglHcmlkRXZlbnQSDwoLR2V0R3JpZERhdGEQABILCgdHZXRSb3dzEAESDQoJR2V0RmllbGRzEAISDQoJQ3JlYXRlUm93EAMSDgoKVXBkYXRlQ2VsbBAE');
