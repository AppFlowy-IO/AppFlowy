///
//  Generated code. Do not modify.
//  source: number_description.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use moneySymbolDescriptor instead')
const MoneySymbol$json = const {
  '1': 'MoneySymbol',
  '2': const [
    const {'1': 'CNY', '2': 0},
    const {'1': 'EUR', '2': 1},
    const {'1': 'USD', '2': 2},
  ],
};

/// Descriptor for `MoneySymbol`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List moneySymbolDescriptor = $convert.base64Decode('CgtNb25leVN5bWJvbBIHCgNDTlkQABIHCgNFVVIQARIHCgNVU0QQAg==');
@$core.Deprecated('Use numberDescriptionDescriptor instead')
const NumberDescription$json = const {
  '1': 'NumberDescription',
  '2': const [
    const {'1': 'money', '3': 1, '4': 1, '5': 14, '6': '.MoneySymbol', '10': 'money'},
    const {'1': 'scale', '3': 2, '4': 1, '5': 13, '10': 'scale'},
    const {'1': 'symbol', '3': 3, '4': 1, '5': 9, '10': 'symbol'},
    const {'1': 'sign_positive', '3': 4, '4': 1, '5': 8, '10': 'signPositive'},
    const {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `NumberDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List numberDescriptionDescriptor = $convert.base64Decode('ChFOdW1iZXJEZXNjcmlwdGlvbhIiCgVtb25leRgBIAEoDjIMLk1vbmV5U3ltYm9sUgVtb25leRIUCgVzY2FsZRgCIAEoDVIFc2NhbGUSFgoGc3ltYm9sGAMgASgJUgZzeW1ib2wSIwoNc2lnbl9wb3NpdGl2ZRgEIAEoCFIMc2lnblBvc2l0aXZlEhIKBG5hbWUYBSABKAlSBG5hbWU=');
