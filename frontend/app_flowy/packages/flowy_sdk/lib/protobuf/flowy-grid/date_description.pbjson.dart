///
//  Generated code. Do not modify.
//  source: date_description.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use dateFormatDescriptor instead')
const DateFormat$json = const {
  '1': 'DateFormat',
  '2': const [
    const {'1': 'Local', '2': 0},
    const {'1': 'US', '2': 1},
    const {'1': 'ISO', '2': 2},
    const {'1': 'Friendly', '2': 3},
  ],
};

/// Descriptor for `DateFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List dateFormatDescriptor = $convert.base64Decode('CgpEYXRlRm9ybWF0EgkKBUxvY2FsEAASBgoCVVMQARIHCgNJU08QAhIMCghGcmllbmRseRAD');
@$core.Deprecated('Use timeFormatDescriptor instead')
const TimeFormat$json = const {
  '1': 'TimeFormat',
  '2': const [
    const {'1': 'TwelveHour', '2': 0},
    const {'1': 'TwentyFourHour', '2': 1},
  ],
};

/// Descriptor for `TimeFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List timeFormatDescriptor = $convert.base64Decode('CgpUaW1lRm9ybWF0Eg4KClR3ZWx2ZUhvdXIQABISCg5Ud2VudHlGb3VySG91chAB');
@$core.Deprecated('Use dateDescriptionDescriptor instead')
const DateDescription$json = const {
  '1': 'DateDescription',
  '2': const [
    const {'1': 'date_format', '3': 1, '4': 1, '5': 14, '6': '.DateFormat', '10': 'dateFormat'},
    const {'1': 'time_format', '3': 2, '4': 1, '5': 14, '6': '.TimeFormat', '10': 'timeFormat'},
  ],
};

/// Descriptor for `DateDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dateDescriptionDescriptor = $convert.base64Decode('Cg9EYXRlRGVzY3JpcHRpb24SLAoLZGF0ZV9mb3JtYXQYASABKA4yCy5EYXRlRm9ybWF0UgpkYXRlRm9ybWF0EiwKC3RpbWVfZm9ybWF0GAIgASgOMgsuVGltZUZvcm1hdFIKdGltZUZvcm1hdA==');
