///
//  Generated code. Do not modify.
//  source: selection_description.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
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
