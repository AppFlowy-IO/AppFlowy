///
//  Generated code. Do not modify.
//  source: date_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use dateFilterConditionPBDescriptor instead')
const DateFilterConditionPB$json = const {
  '1': 'DateFilterConditionPB',
  '2': const [
    const {'1': 'DateIs', '2': 0},
    const {'1': 'DateBefore', '2': 1},
    const {'1': 'DateAfter', '2': 2},
    const {'1': 'DateOnOrBefore', '2': 3},
    const {'1': 'DateOnOrAfter', '2': 4},
    const {'1': 'DateWithIn', '2': 5},
    const {'1': 'DateIsEmpty', '2': 6},
    const {'1': 'DateIsNotEmpty', '2': 7},
  ],
};

/// Descriptor for `DateFilterConditionPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List dateFilterConditionPBDescriptor = $convert.base64Decode('ChVEYXRlRmlsdGVyQ29uZGl0aW9uUEISCgoGRGF0ZUlzEAASDgoKRGF0ZUJlZm9yZRABEg0KCURhdGVBZnRlchACEhIKDkRhdGVPbk9yQmVmb3JlEAMSEQoNRGF0ZU9uT3JBZnRlchAEEg4KCkRhdGVXaXRoSW4QBRIPCgtEYXRlSXNFbXB0eRAGEhIKDkRhdGVJc05vdEVtcHR5EAc=');
@$core.Deprecated('Use dateFilterPBDescriptor instead')
const DateFilterPB$json = const {
  '1': 'DateFilterPB',
  '2': const [
    const {'1': 'condition', '3': 1, '4': 1, '5': 14, '6': '.DateFilterConditionPB', '10': 'condition'},
    const {'1': 'start', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'start'},
    const {'1': 'end', '3': 3, '4': 1, '5': 3, '9': 1, '10': 'end'},
    const {'1': 'timestamp', '3': 4, '4': 1, '5': 3, '9': 2, '10': 'timestamp'},
  ],
  '8': const [
    const {'1': 'one_of_start'},
    const {'1': 'one_of_end'},
    const {'1': 'one_of_timestamp'},
  ],
};

/// Descriptor for `DateFilterPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dateFilterPBDescriptor = $convert.base64Decode('CgxEYXRlRmlsdGVyUEISNAoJY29uZGl0aW9uGAEgASgOMhYuRGF0ZUZpbHRlckNvbmRpdGlvblBCUgljb25kaXRpb24SFgoFc3RhcnQYAiABKANIAFIFc3RhcnQSEgoDZW5kGAMgASgDSAFSA2VuZBIeCgl0aW1lc3RhbXAYBCABKANIAlIJdGltZXN0YW1wQg4KDG9uZV9vZl9zdGFydEIMCgpvbmVfb2ZfZW5kQhIKEG9uZV9vZl90aW1lc3RhbXA=');
