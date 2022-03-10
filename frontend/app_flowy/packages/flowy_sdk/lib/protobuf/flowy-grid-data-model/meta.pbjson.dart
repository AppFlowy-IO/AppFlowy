///
//  Generated code. Do not modify.
//  source: meta.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use fieldTypeDescriptor instead')
const FieldType$json = const {
  '1': 'FieldType',
  '2': const [
    const {'1': 'RichText', '2': 0},
    const {'1': 'Number', '2': 1},
    const {'1': 'DateTime', '2': 2},
    const {'1': 'SingleSelect', '2': 3},
    const {'1': 'MultiSelect', '2': 4},
    const {'1': 'Checkbox', '2': 5},
  ],
};

/// Descriptor for `FieldType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fieldTypeDescriptor = $convert.base64Decode('CglGaWVsZFR5cGUSDAoIUmljaFRleHQQABIKCgZOdW1iZXIQARIMCghEYXRlVGltZRACEhAKDFNpbmdsZVNlbGVjdBADEg8KC011bHRpU2VsZWN0EAQSDAoIQ2hlY2tib3gQBQ==');
@$core.Deprecated('Use gridMetaDescriptor instead')
const GridMeta$json = const {
  '1': 'GridMeta',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'fields', '3': 2, '4': 3, '5': 11, '6': '.Field', '10': 'fields'},
    const {'1': 'blocks', '3': 3, '4': 3, '5': 11, '6': '.Block', '10': 'blocks'},
  ],
};

/// Descriptor for `GridMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridMetaDescriptor = $convert.base64Decode('CghHcmlkTWV0YRIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSHgoGZmllbGRzGAIgAygLMgYuRmllbGRSBmZpZWxkcxIeCgZibG9ja3MYAyADKAsyBi5CbG9ja1IGYmxvY2tz');
@$core.Deprecated('Use blockDescriptor instead')
const Block$json = const {
  '1': 'Block',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'start_row_index', '3': 2, '4': 1, '5': 5, '10': 'startRowIndex'},
    const {'1': 'row_count', '3': 3, '4': 1, '5': 5, '10': 'rowCount'},
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode('CgVCbG9jaxIOCgJpZBgBIAEoCVICaWQSJgoPc3RhcnRfcm93X2luZGV4GAIgASgFUg1zdGFydFJvd0luZGV4EhsKCXJvd19jb3VudBgDIAEoBVIIcm93Q291bnQ=');
@$core.Deprecated('Use blockMetaDescriptor instead')
const BlockMeta$json = const {
  '1': 'BlockMeta',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'rows', '3': 2, '4': 3, '5': 11, '6': '.RowMeta', '10': 'rows'},
  ],
};

/// Descriptor for `BlockMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockMetaDescriptor = $convert.base64Decode('CglCbG9ja01ldGESGQoIYmxvY2tfaWQYASABKAlSB2Jsb2NrSWQSHAoEcm93cxgCIAMoCzIILlJvd01ldGFSBHJvd3M=');
@$core.Deprecated('Use fieldDescriptor instead')
const Field$json = const {
  '1': 'Field',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'field_type', '3': 4, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'frozen', '3': 5, '4': 1, '5': 8, '10': 'frozen'},
    const {'1': 'visibility', '3': 6, '4': 1, '5': 8, '10': 'visibility'},
    const {'1': 'width', '3': 7, '4': 1, '5': 5, '10': 'width'},
    const {'1': 'type_options', '3': 8, '4': 1, '5': 11, '6': '.AnyData', '10': 'typeOptions'},
  ],
};

/// Descriptor for `Field`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldDescriptor = $convert.base64Decode('CgVGaWVsZBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEikKCmZpZWxkX3R5cGUYBCABKA4yCi5GaWVsZFR5cGVSCWZpZWxkVHlwZRIWCgZmcm96ZW4YBSABKAhSBmZyb3plbhIeCgp2aXNpYmlsaXR5GAYgASgIUgp2aXNpYmlsaXR5EhQKBXdpZHRoGAcgASgFUgV3aWR0aBIrCgx0eXBlX29wdGlvbnMYCCABKAsyCC5BbnlEYXRhUgt0eXBlT3B0aW9ucw==');
@$core.Deprecated('Use repeatedFieldDescriptor instead')
const RepeatedField$json = const {
  '1': 'RepeatedField',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.Field', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedField`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedFieldDescriptor = $convert.base64Decode('Cg1SZXBlYXRlZEZpZWxkEhwKBWl0ZW1zGAEgAygLMgYuRmllbGRSBWl0ZW1z');
@$core.Deprecated('Use anyDataDescriptor instead')
const AnyData$json = const {
  '1': 'AnyData',
  '2': const [
    const {'1': 'type_id', '3': 1, '4': 1, '5': 9, '10': 'typeId'},
    const {'1': 'value', '3': 2, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `AnyData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List anyDataDescriptor = $convert.base64Decode('CgdBbnlEYXRhEhcKB3R5cGVfaWQYASABKAlSBnR5cGVJZBIUCgV2YWx1ZRgCIAEoDFIFdmFsdWU=');
@$core.Deprecated('Use rowMetaDescriptor instead')
const RowMeta$json = const {
  '1': 'RowMeta',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'cell_by_field_id', '3': 3, '4': 3, '5': 11, '6': '.RowMeta.CellByFieldIdEntry', '10': 'cellByFieldId'},
    const {'1': 'height', '3': 4, '4': 1, '5': 5, '10': 'height'},
    const {'1': 'visibility', '3': 5, '4': 1, '5': 8, '10': 'visibility'},
  ],
  '3': const [RowMeta_CellByFieldIdEntry$json],
};

@$core.Deprecated('Use rowMetaDescriptor instead')
const RowMeta_CellByFieldIdEntry$json = const {
  '1': 'CellByFieldIdEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.CellMeta', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `RowMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowMetaDescriptor = $convert.base64Decode('CgdSb3dNZXRhEg4KAmlkGAEgASgJUgJpZBIXCgdncmlkX2lkGAIgASgJUgZncmlkSWQSRAoQY2VsbF9ieV9maWVsZF9pZBgDIAMoCzIbLlJvd01ldGEuQ2VsbEJ5RmllbGRJZEVudHJ5Ug1jZWxsQnlGaWVsZElkEhYKBmhlaWdodBgEIAEoBVIGaGVpZ2h0Eh4KCnZpc2liaWxpdHkYBSABKAhSCnZpc2liaWxpdHkaSwoSQ2VsbEJ5RmllbGRJZEVudHJ5EhAKA2tleRgBIAEoCVIDa2V5Eh8KBXZhbHVlGAIgASgLMgkuQ2VsbE1ldGFSBXZhbHVlOgI4AQ==');
@$core.Deprecated('Use rowMetaChangesetDescriptor instead')
const RowMetaChangeset$json = const {
  '1': 'RowMetaChangeset',
  '2': const [
    const {'1': 'row_id', '3': 1, '4': 1, '5': 9, '10': 'rowId'},
    const {'1': 'height', '3': 2, '4': 1, '5': 5, '9': 0, '10': 'height'},
    const {'1': 'visibility', '3': 3, '4': 1, '5': 8, '9': 1, '10': 'visibility'},
    const {'1': 'cell_by_field_id', '3': 4, '4': 3, '5': 11, '6': '.RowMetaChangeset.CellByFieldIdEntry', '10': 'cellByFieldId'},
  ],
  '3': const [RowMetaChangeset_CellByFieldIdEntry$json],
  '8': const [
    const {'1': 'one_of_height'},
    const {'1': 'one_of_visibility'},
  ],
};

@$core.Deprecated('Use rowMetaChangesetDescriptor instead')
const RowMetaChangeset_CellByFieldIdEntry$json = const {
  '1': 'CellByFieldIdEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.CellMeta', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `RowMetaChangeset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowMetaChangesetDescriptor = $convert.base64Decode('ChBSb3dNZXRhQ2hhbmdlc2V0EhUKBnJvd19pZBgBIAEoCVIFcm93SWQSGAoGaGVpZ2h0GAIgASgFSABSBmhlaWdodBIgCgp2aXNpYmlsaXR5GAMgASgISAFSCnZpc2liaWxpdHkSTQoQY2VsbF9ieV9maWVsZF9pZBgEIAMoCzIkLlJvd01ldGFDaGFuZ2VzZXQuQ2VsbEJ5RmllbGRJZEVudHJ5Ug1jZWxsQnlGaWVsZElkGksKEkNlbGxCeUZpZWxkSWRFbnRyeRIQCgNrZXkYASABKAlSA2tleRIfCgV2YWx1ZRgCIAEoCzIJLkNlbGxNZXRhUgV2YWx1ZToCOAFCDwoNb25lX29mX2hlaWdodEITChFvbmVfb2ZfdmlzaWJpbGl0eQ==');
@$core.Deprecated('Use cellMetaDescriptor instead')
const CellMeta$json = const {
  '1': 'CellMeta',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'row_id', '3': 2, '4': 1, '5': 9, '10': 'rowId'},
    const {'1': 'field_id', '3': 3, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'data', '3': 4, '4': 1, '5': 11, '6': '.AnyData', '10': 'data'},
    const {'1': 'height', '3': 5, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `CellMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellMetaDescriptor = $convert.base64Decode('CghDZWxsTWV0YRIOCgJpZBgBIAEoCVICaWQSFQoGcm93X2lkGAIgASgJUgVyb3dJZBIZCghmaWVsZF9pZBgDIAEoCVIHZmllbGRJZBIcCgRkYXRhGAQgASgLMgguQW55RGF0YVIEZGF0YRIWCgZoZWlnaHQYBSABKAVSBmhlaWdodA==');
