///
//  Generated code. Do not modify.
//  source: select_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use selectOptionColorPBDescriptor instead')
const SelectOptionColorPB$json = const {
  '1': 'SelectOptionColorPB',
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

/// Descriptor for `SelectOptionColorPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List selectOptionColorPBDescriptor = $convert.base64Decode('ChNTZWxlY3RPcHRpb25Db2xvclBCEgoKBlB1cnBsZRAAEggKBFBpbmsQARINCglMaWdodFBpbmsQAhIKCgZPcmFuZ2UQAxIKCgZZZWxsb3cQBBIICgRMaW1lEAUSCQoFR3JlZW4QBhIICgRBcXVhEAcSCAoEQmx1ZRAI');
@$core.Deprecated('Use selectOptionPBDescriptor instead')
const SelectOptionPB$json = const {
  '1': 'SelectOptionPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'color', '3': 3, '4': 1, '5': 14, '6': '.SelectOptionColorPB', '10': 'color'},
  ],
};

/// Descriptor for `SelectOptionPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionPBDescriptor = $convert.base64Decode('Cg5TZWxlY3RPcHRpb25QQhIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIqCgVjb2xvchgDIAEoDjIULlNlbGVjdE9wdGlvbkNvbG9yUEJSBWNvbG9y');
@$core.Deprecated('Use selectOptionCellChangesetPBDescriptor instead')
const SelectOptionCellChangesetPB$json = const {
  '1': 'SelectOptionCellChangesetPB',
  '2': const [
    const {'1': 'cell_identifier', '3': 1, '4': 1, '5': 11, '6': '.CellPathPB', '10': 'cellIdentifier'},
    const {'1': 'insert_option_ids', '3': 2, '4': 3, '5': 9, '10': 'insertOptionIds'},
    const {'1': 'delete_option_ids', '3': 3, '4': 3, '5': 9, '10': 'deleteOptionIds'},
  ],
};

/// Descriptor for `SelectOptionCellChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionCellChangesetPBDescriptor = $convert.base64Decode('ChtTZWxlY3RPcHRpb25DZWxsQ2hhbmdlc2V0UEISNAoPY2VsbF9pZGVudGlmaWVyGAEgASgLMgsuQ2VsbFBhdGhQQlIOY2VsbElkZW50aWZpZXISKgoRaW5zZXJ0X29wdGlvbl9pZHMYAiADKAlSD2luc2VydE9wdGlvbklkcxIqChFkZWxldGVfb3B0aW9uX2lkcxgDIAMoCVIPZGVsZXRlT3B0aW9uSWRz');
@$core.Deprecated('Use selectOptionCellDataPBDescriptor instead')
const SelectOptionCellDataPB$json = const {
  '1': 'SelectOptionCellDataPB',
  '2': const [
    const {'1': 'options', '3': 1, '4': 3, '5': 11, '6': '.SelectOptionPB', '10': 'options'},
    const {'1': 'select_options', '3': 2, '4': 3, '5': 11, '6': '.SelectOptionPB', '10': 'selectOptions'},
  ],
};

/// Descriptor for `SelectOptionCellDataPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionCellDataPBDescriptor = $convert.base64Decode('ChZTZWxlY3RPcHRpb25DZWxsRGF0YVBCEikKB29wdGlvbnMYASADKAsyDy5TZWxlY3RPcHRpb25QQlIHb3B0aW9ucxI2Cg5zZWxlY3Rfb3B0aW9ucxgCIAMoCzIPLlNlbGVjdE9wdGlvblBCUg1zZWxlY3RPcHRpb25z');
@$core.Deprecated('Use selectOptionChangesetPBDescriptor instead')
const SelectOptionChangesetPB$json = const {
  '1': 'SelectOptionChangesetPB',
  '2': const [
    const {'1': 'cell_identifier', '3': 1, '4': 1, '5': 11, '6': '.CellPathPB', '10': 'cellIdentifier'},
    const {'1': 'insert_options', '3': 2, '4': 3, '5': 11, '6': '.SelectOptionPB', '10': 'insertOptions'},
    const {'1': 'update_options', '3': 3, '4': 3, '5': 11, '6': '.SelectOptionPB', '10': 'updateOptions'},
    const {'1': 'delete_options', '3': 4, '4': 3, '5': 11, '6': '.SelectOptionPB', '10': 'deleteOptions'},
  ],
};

/// Descriptor for `SelectOptionChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectOptionChangesetPBDescriptor = $convert.base64Decode('ChdTZWxlY3RPcHRpb25DaGFuZ2VzZXRQQhI0Cg9jZWxsX2lkZW50aWZpZXIYASABKAsyCy5DZWxsUGF0aFBCUg5jZWxsSWRlbnRpZmllchI2Cg5pbnNlcnRfb3B0aW9ucxgCIAMoCzIPLlNlbGVjdE9wdGlvblBCUg1pbnNlcnRPcHRpb25zEjYKDnVwZGF0ZV9vcHRpb25zGAMgAygLMg8uU2VsZWN0T3B0aW9uUEJSDXVwZGF0ZU9wdGlvbnMSNgoOZGVsZXRlX29wdGlvbnMYBCADKAsyDy5TZWxlY3RPcHRpb25QQlINZGVsZXRlT3B0aW9ucw==');
