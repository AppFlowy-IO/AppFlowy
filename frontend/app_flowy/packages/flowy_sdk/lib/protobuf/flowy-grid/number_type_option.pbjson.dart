///
//  Generated code. Do not modify.
//  source: number_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use numberFormatDescriptor instead')
const NumberFormat$json = const {
  '1': 'NumberFormat',
  '2': const [
    const {'1': 'Number', '2': 0},
    const {'1': 'USD', '2': 1},
    const {'1': 'CNY', '2': 2},
    const {'1': 'EUR', '2': 3},
  ],
};

/// Descriptor for `NumberFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List numberFormatDescriptor = $convert.base64Decode('CgxOdW1iZXJGb3JtYXQSCgoGTnVtYmVyEAASBwoDVVNEEAESBwoDQ05ZEAISBwoDRVVSEAM=');
@$core.Deprecated('Use numberTypeOptionDescriptor instead')
const NumberTypeOption$json = const {
  '1': 'NumberTypeOption',
  '2': const [
    const {'1': 'format', '3': 1, '4': 1, '5': 14, '6': '.NumberFormat', '10': 'format'},
    const {'1': 'scale', '3': 2, '4': 1, '5': 13, '10': 'scale'},
    const {'1': 'symbol', '3': 3, '4': 1, '5': 9, '10': 'symbol'},
    const {'1': 'sign_positive', '3': 4, '4': 1, '5': 8, '10': 'signPositive'},
    const {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `NumberTypeOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List numberTypeOptionDescriptor = $convert.base64Decode('ChBOdW1iZXJUeXBlT3B0aW9uEiUKBmZvcm1hdBgBIAEoDjINLk51bWJlckZvcm1hdFIGZm9ybWF0EhQKBXNjYWxlGAIgASgNUgVzY2FsZRIWCgZzeW1ib2wYAyABKAlSBnN5bWJvbBIjCg1zaWduX3Bvc2l0aXZlGAQgASgIUgxzaWduUG9zaXRpdmUSEgoEbmFtZRgFIAEoCVIEbmFtZQ==');
