///
//  Generated code. Do not modify.
//  source: dart_notification.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use gridNotificationDescriptor instead')
const GridNotification$json = const {
  '1': 'GridNotification',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'GridDidCreateBlock', '2': 11},
    const {'1': 'BlockDidUpdateRow', '2': 20},
    const {'1': 'GridDidUpdateCells', '2': 30},
    const {'1': 'GridDidUpdateFields', '2': 40},
  ],
};

/// Descriptor for `GridNotification`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gridNotificationDescriptor = $convert.base64Decode('ChBHcmlkTm90aWZpY2F0aW9uEgsKB1Vua25vd24QABIWChJHcmlkRGlkQ3JlYXRlQmxvY2sQCxIVChFCbG9ja0RpZFVwZGF0ZVJvdxAUEhYKEkdyaWREaWRVcGRhdGVDZWxscxAeEhcKE0dyaWREaWRVcGRhdGVGaWVsZHMQKA==');
