///
//  Generated code. Do not modify.
//  source: number_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use numberFilterConditionPBDescriptor instead')
const NumberFilterConditionPB$json = const {
  '1': 'NumberFilterConditionPB',
  '2': const [
    const {'1': 'Equal', '2': 0},
    const {'1': 'NotEqual', '2': 1},
    const {'1': 'GreaterThan', '2': 2},
    const {'1': 'LessThan', '2': 3},
    const {'1': 'GreaterThanOrEqualTo', '2': 4},
    const {'1': 'LessThanOrEqualTo', '2': 5},
    const {'1': 'NumberIsEmpty', '2': 6},
    const {'1': 'NumberIsNotEmpty', '2': 7},
  ],
};

/// Descriptor for `NumberFilterConditionPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List numberFilterConditionPBDescriptor = $convert.base64Decode('ChdOdW1iZXJGaWx0ZXJDb25kaXRpb25QQhIJCgVFcXVhbBAAEgwKCE5vdEVxdWFsEAESDwoLR3JlYXRlclRoYW4QAhIMCghMZXNzVGhhbhADEhgKFEdyZWF0ZXJUaGFuT3JFcXVhbFRvEAQSFQoRTGVzc1RoYW5PckVxdWFsVG8QBRIRCg1OdW1iZXJJc0VtcHR5EAYSFAoQTnVtYmVySXNOb3RFbXB0eRAH');
@$core.Deprecated('Use numberFilterPBDescriptor instead')
const NumberFilterPB$json = const {
  '1': 'NumberFilterPB',
  '2': const [
    const {'1': 'condition', '3': 1, '4': 1, '5': 14, '6': '.NumberFilterConditionPB', '10': 'condition'},
    const {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `NumberFilterPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List numberFilterPBDescriptor = $convert.base64Decode('Cg5OdW1iZXJGaWx0ZXJQQhI2Cgljb25kaXRpb24YASABKA4yGC5OdW1iZXJGaWx0ZXJDb25kaXRpb25QQlIJY29uZGl0aW9uEhgKB2NvbnRlbnQYAiABKAlSB2NvbnRlbnQ=');
