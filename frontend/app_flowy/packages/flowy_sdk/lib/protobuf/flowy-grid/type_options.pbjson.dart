///
//  Generated code. Do not modify.
//  source: type_options.proto
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
@$core.Deprecated('Use richTextDescriptionDescriptor instead')
const RichTextDescription$json = const {
  '1': 'RichTextDescription',
  '2': const [
    const {'1': 'format', '3': 1, '4': 1, '5': 9, '10': 'format'},
  ],
};

/// Descriptor for `RichTextDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List richTextDescriptionDescriptor = $convert.base64Decode('ChNSaWNoVGV4dERlc2NyaXB0aW9uEhYKBmZvcm1hdBgBIAEoCVIGZm9ybWF0');
@$core.Deprecated('Use checkboxDescriptionDescriptor instead')
const CheckboxDescription$json = const {
  '1': 'CheckboxDescription',
  '2': const [
    const {'1': 'is_selected', '3': 1, '4': 1, '5': 8, '10': 'isSelected'},
  ],
};

/// Descriptor for `CheckboxDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkboxDescriptionDescriptor = $convert.base64Decode('ChNDaGVja2JveERlc2NyaXB0aW9uEh8KC2lzX3NlbGVjdGVkGAEgASgIUgppc1NlbGVjdGVk');
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
@$core.Deprecated('Use singleSelectDescriptionDescriptor instead')
const SingleSelectDescription$json = const {
  '1': 'SingleSelectDescription',
  '2': const [
    const {'1': 'options', '3': 1, '4': 3, '5': 11, '6': '.SelectOption', '10': 'options'},
    const {'1': 'disable_color', '3': 2, '4': 1, '5': 8, '10': 'disableColor'},
  ],
};

/// Descriptor for `SingleSelectDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List singleSelectDescriptionDescriptor = $convert.base64Decode('ChdTaW5nbGVTZWxlY3REZXNjcmlwdGlvbhInCgdvcHRpb25zGAEgAygLMg0uU2VsZWN0T3B0aW9uUgdvcHRpb25zEiMKDWRpc2FibGVfY29sb3IYAiABKAhSDGRpc2FibGVDb2xvcg==');
@$core.Deprecated('Use multiSelectDescriptionDescriptor instead')
const MultiSelectDescription$json = const {
  '1': 'MultiSelectDescription',
  '2': const [
    const {'1': 'options', '3': 1, '4': 3, '5': 11, '6': '.SelectOption', '10': 'options'},
    const {'1': 'disable_color', '3': 2, '4': 1, '5': 8, '10': 'disableColor'},
  ],
};

/// Descriptor for `MultiSelectDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List multiSelectDescriptionDescriptor = $convert.base64Decode('ChZNdWx0aVNlbGVjdERlc2NyaXB0aW9uEicKB29wdGlvbnMYASADKAsyDS5TZWxlY3RPcHRpb25SB29wdGlvbnMSIwoNZGlzYWJsZV9jb2xvchgCIAEoCFIMZGlzYWJsZUNvbG9y');
@$core.Deprecated('Use selectOptionDescriptor instead')
const SelectOption$json = const {
  '1': 'SelectOption',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'color', '3': 3, '4': 1, '5': 9, '10': 'color'},
  ],
};

/// Descriptor for `SelectOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionDescriptor = $convert.base64Decode('CgxTZWxlY3RPcHRpb24SDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSFAoFY29sb3IYAyABKAlSBWNvbG9y');
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
