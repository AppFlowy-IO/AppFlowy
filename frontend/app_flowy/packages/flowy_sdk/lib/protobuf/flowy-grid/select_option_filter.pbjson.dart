///
//  Generated code. Do not modify.
//  source: select_option_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use selectOptionConditionPBDescriptor instead')
const SelectOptionConditionPB$json = const {
  '1': 'SelectOptionConditionPB',
  '2': const [
    const {'1': 'OptionIs', '2': 0},
    const {'1': 'OptionIsNot', '2': 1},
    const {'1': 'OptionIsEmpty', '2': 2},
    const {'1': 'OptionIsNotEmpty', '2': 3},
  ],
};

/// Descriptor for `SelectOptionConditionPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List selectOptionConditionPBDescriptor = $convert.base64Decode('ChdTZWxlY3RPcHRpb25Db25kaXRpb25QQhIMCghPcHRpb25JcxAAEg8KC09wdGlvbklzTm90EAESEQoNT3B0aW9uSXNFbXB0eRACEhQKEE9wdGlvbklzTm90RW1wdHkQAw==');
@$core.Deprecated('Use selectOptionFilterPBDescriptor instead')
const SelectOptionFilterPB$json = const {
  '1': 'SelectOptionFilterPB',
  '2': const [
    const {'1': 'condition', '3': 1, '4': 1, '5': 14, '6': '.SelectOptionConditionPB', '10': 'condition'},
    const {'1': 'option_ids', '3': 2, '4': 3, '5': 9, '10': 'optionIds'},
  ],
};

/// Descriptor for `SelectOptionFilterPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionFilterPBDescriptor = $convert.base64Decode('ChRTZWxlY3RPcHRpb25GaWx0ZXJQQhI2Cgljb25kaXRpb24YASABKA4yGC5TZWxlY3RPcHRpb25Db25kaXRpb25QQlIJY29uZGl0aW9uEh0KCm9wdGlvbl9pZHMYAiADKAlSCW9wdGlvbklkcw==');
