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
    const {'1': 'GetGridBlocks', '2': 1},
    const {'1': 'GetFields', '2': 10},
    const {'1': 'UpdateField', '2': 11},
    const {'1': 'CreateField', '2': 12},
    const {'1': 'DeleteField', '2': 13},
    const {'1': 'DuplicateField', '2': 15},
    const {'1': 'CreateEditFieldContext', '2': 16},
    const {'1': 'CreateSelectOption', '2': 30},
    const {'1': 'CreateRow', '2': 50},
    const {'1': 'GetRow', '2': 51},
    const {'1': 'UpdateCell', '2': 70},
  ],
};

/// Descriptor for `GridEvent`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gridEventDescriptor = $convert.base64Decode('CglHcmlkRXZlbnQSDwoLR2V0R3JpZERhdGEQABIRCg1HZXRHcmlkQmxvY2tzEAESDQoJR2V0RmllbGRzEAoSDwoLVXBkYXRlRmllbGQQCxIPCgtDcmVhdGVGaWVsZBAMEg8KC0RlbGV0ZUZpZWxkEA0SEgoORHVwbGljYXRlRmllbGQQDxIaChZDcmVhdGVFZGl0RmllbGRDb250ZXh0EBASFgoSQ3JlYXRlU2VsZWN0T3B0aW9uEB4SDQoJQ3JlYXRlUm93EDISCgoGR2V0Um93EDMSDgoKVXBkYXRlQ2VsbBBG');
