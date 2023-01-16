///
//  Generated code. Do not modify.
//  source: date_type_option_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

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
@$core.Deprecated('Use dateCellDataPBDescriptor instead')
const DateCellDataPB$json = const {
  '1': 'DateCellDataPB',
  '2': const [
    const {'1': 'date', '3': 1, '4': 1, '5': 9, '10': 'date'},
    const {'1': 'time', '3': 2, '4': 1, '5': 9, '10': 'time'},
    const {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `DateCellDataPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dateCellDataPBDescriptor = $convert.base64Decode('Cg5EYXRlQ2VsbERhdGFQQhISCgRkYXRlGAEgASgJUgRkYXRlEhIKBHRpbWUYAiABKAlSBHRpbWUSHAoJdGltZXN0YW1wGAMgASgDUgl0aW1lc3RhbXA=');
@$core.Deprecated('Use dateChangesetPBDescriptor instead')
const DateChangesetPB$json = const {
  '1': 'DateChangesetPB',
  '2': const [
    const {'1': 'cell_path', '3': 1, '4': 1, '5': 11, '6': '.CellPathPB', '10': 'cellPath'},
    const {'1': 'date', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'date'},
    const {'1': 'time', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'time'},
    const {'1': 'is_utc', '3': 4, '4': 1, '5': 8, '10': 'isUtc'},
  ],
  '8': const [
    const {'1': 'one_of_date'},
    const {'1': 'one_of_time'},
  ],
};

/// Descriptor for `DateChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dateChangesetPBDescriptor = $convert.base64Decode('Cg9EYXRlQ2hhbmdlc2V0UEISKAoJY2VsbF9wYXRoGAEgASgLMgsuQ2VsbFBhdGhQQlIIY2VsbFBhdGgSFAoEZGF0ZRgCIAEoCUgAUgRkYXRlEhQKBHRpbWUYAyABKAlIAVIEdGltZRIVCgZpc191dGMYBCABKAhSBWlzVXRjQg0KC29uZV9vZl9kYXRlQg0KC29uZV9vZl90aW1l');
