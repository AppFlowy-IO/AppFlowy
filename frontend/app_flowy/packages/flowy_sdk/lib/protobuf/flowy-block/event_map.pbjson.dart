///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use blockEventDescriptor instead')
const BlockEvent$json = const {
  '1': 'BlockEvent',
  '2': const [
    const {'1': 'GetBlockData', '2': 0},
    const {'1': 'ApplyDelta', '2': 1},
    const {'1': 'ExportDocument', '2': 2},
  ],
};

/// Descriptor for `BlockEvent`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List blockEventDescriptor = $convert.base64Decode('CgpCbG9ja0V2ZW50EhAKDEdldEJsb2NrRGF0YRAAEg4KCkFwcGx5RGVsdGEQARISCg5FeHBvcnREb2N1bWVudBAC');
