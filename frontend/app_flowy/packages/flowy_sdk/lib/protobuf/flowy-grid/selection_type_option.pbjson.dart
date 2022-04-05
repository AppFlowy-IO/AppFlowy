///
//  Generated code. Do not modify.
//  source: selection_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use selectOptionColorDescriptor instead')
const SelectOptionColor$json = const {
  '1': 'SelectOptionColor',
  '2': const [
    const {'1': 'Purple', '2': 0},
    const {'1': 'Pink', '2': 1},
    const {'1': 'LightPink', '2': 2},
    const {'1': 'Orange', '2': 3},
    const {'1': 'Yellow', '2': 4},
    const {'1': 'Lime', '2': 5},
    const {'1': 'Green', '2': 6},
    const {'1': 'Aqua', '2': 7},
    const {'1': 'Blue', '2': 8},
  ],
};

/// Descriptor for `SelectOptionColor`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List selectOptionColorDescriptor = $convert.base64Decode('ChFTZWxlY3RPcHRpb25Db2xvchIKCgZQdXJwbGUQABIICgRQaW5rEAESDQoJTGlnaHRQaW5rEAISCgoGT3JhbmdlEAMSCgoGWWVsbG93EAQSCAoETGltZRAFEgkKBUdyZWVuEAYSCAoEQXF1YRAHEggKBEJsdWUQCA==');
@$core.Deprecated('Use singleSelectTypeOptionDescriptor instead')
const SingleSelectTypeOption$json = const {
  '1': 'SingleSelectTypeOption',
  '2': const [
    const {'1': 'options', '3': 1, '4': 3, '5': 11, '6': '.SelectOption', '10': 'options'},
    const {'1': 'disable_color', '3': 2, '4': 1, '5': 8, '10': 'disableColor'},
  ],
};

/// Descriptor for `SingleSelectTypeOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List singleSelectTypeOptionDescriptor = $convert.base64Decode('ChZTaW5nbGVTZWxlY3RUeXBlT3B0aW9uEicKB29wdGlvbnMYASADKAsyDS5TZWxlY3RPcHRpb25SB29wdGlvbnMSIwoNZGlzYWJsZV9jb2xvchgCIAEoCFIMZGlzYWJsZUNvbG9y');
@$core.Deprecated('Use multiSelectTypeOptionDescriptor instead')
const MultiSelectTypeOption$json = const {
  '1': 'MultiSelectTypeOption',
  '2': const [
    const {'1': 'options', '3': 1, '4': 3, '5': 11, '6': '.SelectOption', '10': 'options'},
    const {'1': 'disable_color', '3': 2, '4': 1, '5': 8, '10': 'disableColor'},
  ],
};

/// Descriptor for `MultiSelectTypeOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List multiSelectTypeOptionDescriptor = $convert.base64Decode('ChVNdWx0aVNlbGVjdFR5cGVPcHRpb24SJwoHb3B0aW9ucxgBIAMoCzINLlNlbGVjdE9wdGlvblIHb3B0aW9ucxIjCg1kaXNhYmxlX2NvbG9yGAIgASgIUgxkaXNhYmxlQ29sb3I=');
@$core.Deprecated('Use selectOptionDescriptor instead')
const SelectOption$json = const {
  '1': 'SelectOption',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'color', '3': 3, '4': 1, '5': 14, '6': '.SelectOptionColor', '10': 'color'},
  ],
};

/// Descriptor for `SelectOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionDescriptor = $convert.base64Decode('CgxTZWxlY3RPcHRpb24SDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSKAoFY29sb3IYAyABKA4yEi5TZWxlY3RPcHRpb25Db2xvclIFY29sb3I=');
@$core.Deprecated('Use selectOptionChangesetPayloadDescriptor instead')
const SelectOptionChangesetPayload$json = const {
  '1': 'SelectOptionChangesetPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'row_id', '3': 2, '4': 1, '5': 9, '10': 'rowId'},
    const {'1': 'field_id', '3': 3, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'insert_option_id', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'insertOptionId'},
    const {'1': 'delete_option_id', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'deleteOptionId'},
  ],
  '8': const [
    const {'1': 'one_of_insert_option_id'},
    const {'1': 'one_of_delete_option_id'},
  ],
};

/// Descriptor for `SelectOptionChangesetPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionChangesetPayloadDescriptor = $convert.base64Decode('ChxTZWxlY3RPcHRpb25DaGFuZ2VzZXRQYXlsb2FkEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIVCgZyb3dfaWQYAiABKAlSBXJvd0lkEhkKCGZpZWxkX2lkGAMgASgJUgdmaWVsZElkEioKEGluc2VydF9vcHRpb25faWQYBCABKAlIAFIOaW5zZXJ0T3B0aW9uSWQSKgoQZGVsZXRlX29wdGlvbl9pZBgFIAEoCUgBUg5kZWxldGVPcHRpb25JZEIZChdvbmVfb2ZfaW5zZXJ0X29wdGlvbl9pZEIZChdvbmVfb2ZfZGVsZXRlX29wdGlvbl9pZA==');
@$core.Deprecated('Use selectOptionContextDescriptor instead')
const SelectOptionContext$json = const {
  '1': 'SelectOptionContext',
  '2': const [
    const {'1': 'options', '3': 1, '4': 3, '5': 11, '6': '.SelectOption', '10': 'options'},
    const {'1': 'select_options', '3': 2, '4': 3, '5': 11, '6': '.SelectOption', '10': 'selectOptions'},
  ],
};

/// Descriptor for `SelectOptionContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionContextDescriptor = $convert.base64Decode('ChNTZWxlY3RPcHRpb25Db250ZXh0EicKB29wdGlvbnMYASADKAsyDS5TZWxlY3RPcHRpb25SB29wdGlvbnMSNAoOc2VsZWN0X29wdGlvbnMYAiADKAsyDS5TZWxlY3RPcHRpb25SDXNlbGVjdE9wdGlvbnM=');
