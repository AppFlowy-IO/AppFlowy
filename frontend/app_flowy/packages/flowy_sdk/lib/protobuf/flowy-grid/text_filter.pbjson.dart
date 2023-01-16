///
//  Generated code. Do not modify.
//  source: text_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use textFilterConditionPBDescriptor instead')
const TextFilterConditionPB$json = const {
  '1': 'TextFilterConditionPB',
  '2': const [
    const {'1': 'Is', '2': 0},
    const {'1': 'IsNot', '2': 1},
    const {'1': 'Contains', '2': 2},
    const {'1': 'DoesNotContain', '2': 3},
    const {'1': 'StartsWith', '2': 4},
    const {'1': 'EndsWith', '2': 5},
    const {'1': 'TextIsEmpty', '2': 6},
    const {'1': 'TextIsNotEmpty', '2': 7},
  ],
};

/// Descriptor for `TextFilterConditionPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List textFilterConditionPBDescriptor = $convert.base64Decode('ChVUZXh0RmlsdGVyQ29uZGl0aW9uUEISBgoCSXMQABIJCgVJc05vdBABEgwKCENvbnRhaW5zEAISEgoORG9lc05vdENvbnRhaW4QAxIOCgpTdGFydHNXaXRoEAQSDAoIRW5kc1dpdGgQBRIPCgtUZXh0SXNFbXB0eRAGEhIKDlRleHRJc05vdEVtcHR5EAc=');
@$core.Deprecated('Use textFilterPBDescriptor instead')
const TextFilterPB$json = const {
  '1': 'TextFilterPB',
  '2': const [
    const {'1': 'condition', '3': 1, '4': 1, '5': 14, '6': '.TextFilterConditionPB', '10': 'condition'},
    const {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `TextFilterPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textFilterPBDescriptor = $convert.base64Decode('CgxUZXh0RmlsdGVyUEISNAoJY29uZGl0aW9uGAEgASgOMhYuVGV4dEZpbHRlckNvbmRpdGlvblBCUgljb25kaXRpb24SGAoHY29udGVudBgCIAEoCVIHY29udGVudA==');
