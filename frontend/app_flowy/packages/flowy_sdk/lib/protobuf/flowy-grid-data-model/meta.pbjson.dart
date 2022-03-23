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
    const {'1': 'fields', '3': 2, '4': 3, '5': 11, '6': '.FieldMeta', '10': 'fields'},
    const {'1': 'block_metas', '3': 3, '4': 3, '5': 11, '6': '.GridBlockMeta', '10': 'blockMetas'},
  ],
};

/// Descriptor for `GridMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridMetaDescriptor = $convert.base64Decode('CghHcmlkTWV0YRIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSIgoGZmllbGRzGAIgAygLMgouRmllbGRNZXRhUgZmaWVsZHMSLwoLYmxvY2tfbWV0YXMYAyADKAsyDi5HcmlkQmxvY2tNZXRhUgpibG9ja01ldGFz');
@$core.Deprecated('Use gridBlockMetaDescriptor instead')
const GridBlockMeta$json = const {
  '1': 'GridBlockMeta',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'start_row_index', '3': 2, '4': 1, '5': 5, '10': 'startRowIndex'},
    const {'1': 'row_count', '3': 3, '4': 1, '5': 5, '10': 'rowCount'},
  ],
};

/// Descriptor for `GridBlockMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridBlockMetaDescriptor = $convert.base64Decode('Cg1HcmlkQmxvY2tNZXRhEhkKCGJsb2NrX2lkGAEgASgJUgdibG9ja0lkEiYKD3N0YXJ0X3Jvd19pbmRleBgCIAEoBVINc3RhcnRSb3dJbmRleBIbCglyb3dfY291bnQYAyABKAVSCHJvd0NvdW50');
@$core.Deprecated('Use gridBlockMetaSerdeDescriptor instead')
const GridBlockMetaSerde$json = const {
  '1': 'GridBlockMetaSerde',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'row_metas', '3': 2, '4': 3, '5': 11, '6': '.RowMeta', '10': 'rowMetas'},
  ],
};

/// Descriptor for `GridBlockMetaSerde`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridBlockMetaSerdeDescriptor = $convert.base64Decode('ChJHcmlkQmxvY2tNZXRhU2VyZGUSGQoIYmxvY2tfaWQYASABKAlSB2Jsb2NrSWQSJQoJcm93X21ldGFzGAIgAygLMgguUm93TWV0YVIIcm93TWV0YXM=');
@$core.Deprecated('Use fieldMetaDescriptor instead')
const FieldMeta$json = const {
  '1': 'FieldMeta',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'field_type', '3': 4, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'frozen', '3': 5, '4': 1, '5': 8, '10': 'frozen'},
    const {'1': 'visibility', '3': 6, '4': 1, '5': 8, '10': 'visibility'},
    const {'1': 'width', '3': 7, '4': 1, '5': 5, '10': 'width'},
    const {'1': 'type_option', '3': 8, '4': 1, '5': 9, '10': 'typeOption'},
  ],
};

/// Descriptor for `FieldMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldMetaDescriptor = $convert.base64Decode('CglGaWVsZE1ldGESDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSEgoEZGVzYxgDIAEoCVIEZGVzYxIpCgpmaWVsZF90eXBlGAQgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGUSFgoGZnJvemVuGAUgASgIUgZmcm96ZW4SHgoKdmlzaWJpbGl0eRgGIAEoCFIKdmlzaWJpbGl0eRIUCgV3aWR0aBgHIAEoBVIFd2lkdGgSHwoLdHlwZV9vcHRpb24YCCABKAlSCnR5cGVPcHRpb24=');
@$core.Deprecated('Use fieldChangesetDescriptor instead')
const FieldChangeset$json = const {
  '1': 'FieldChangeset',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'field_type', '3': 5, '4': 1, '5': 14, '6': '.FieldType', '9': 2, '10': 'fieldType'},
    const {'1': 'frozen', '3': 6, '4': 1, '5': 8, '9': 3, '10': 'frozen'},
    const {'1': 'visibility', '3': 7, '4': 1, '5': 8, '9': 4, '10': 'visibility'},
    const {'1': 'width', '3': 8, '4': 1, '5': 5, '9': 5, '10': 'width'},
    const {'1': 'type_options', '3': 9, '4': 1, '5': 9, '9': 6, '10': 'typeOptions'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_field_type'},
    const {'1': 'one_of_frozen'},
    const {'1': 'one_of_visibility'},
    const {'1': 'one_of_width'},
    const {'1': 'one_of_type_options'},
  ],
};

/// Descriptor for `FieldChangeset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldChangesetDescriptor = $convert.base64Decode('Cg5GaWVsZENoYW5nZXNldBIZCghmaWVsZF9pZBgBIAEoCVIHZmllbGRJZBIXCgdncmlkX2lkGAIgASgJUgZncmlkSWQSFAoEbmFtZRgDIAEoCUgAUgRuYW1lEhQKBGRlc2MYBCABKAlIAVIEZGVzYxIrCgpmaWVsZF90eXBlGAUgASgOMgouRmllbGRUeXBlSAJSCWZpZWxkVHlwZRIYCgZmcm96ZW4YBiABKAhIA1IGZnJvemVuEiAKCnZpc2liaWxpdHkYByABKAhIBFIKdmlzaWJpbGl0eRIWCgV3aWR0aBgIIAEoBUgFUgV3aWR0aBIjCgx0eXBlX29wdGlvbnMYCSABKAlIBlILdHlwZU9wdGlvbnNCDQoLb25lX29mX25hbWVCDQoLb25lX29mX2Rlc2NCEwoRb25lX29mX2ZpZWxkX3R5cGVCDwoNb25lX29mX2Zyb3plbkITChFvbmVfb2ZfdmlzaWJpbGl0eUIOCgxvbmVfb2Zfd2lkdGhCFQoTb25lX29mX3R5cGVfb3B0aW9ucw==');
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
    const {'1': 'block_id', '3': 2, '4': 1, '5': 9, '10': 'blockId'},
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
final $typed_data.Uint8List rowMetaDescriptor = $convert.base64Decode('CgdSb3dNZXRhEg4KAmlkGAEgASgJUgJpZBIZCghibG9ja19pZBgCIAEoCVIHYmxvY2tJZBJEChBjZWxsX2J5X2ZpZWxkX2lkGAMgAygLMhsuUm93TWV0YS5DZWxsQnlGaWVsZElkRW50cnlSDWNlbGxCeUZpZWxkSWQSFgoGaGVpZ2h0GAQgASgFUgZoZWlnaHQSHgoKdmlzaWJpbGl0eRgFIAEoCFIKdmlzaWJpbGl0eRpLChJDZWxsQnlGaWVsZElkRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSHwoFdmFsdWUYAiABKAsyCS5DZWxsTWV0YVIFdmFsdWU6AjgB');
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
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'data', '3': 2, '4': 1, '5': 9, '10': 'data'},
  ],
};

/// Descriptor for `CellMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellMetaDescriptor = $convert.base64Decode('CghDZWxsTWV0YRIZCghmaWVsZF9pZBgBIAEoCVIHZmllbGRJZBISCgRkYXRhGAIgASgJUgRkYXRh');
@$core.Deprecated('Use cellMetaChangesetDescriptor instead')
const CellMetaChangeset$json = const {
  '1': 'CellMetaChangeset',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'row_id', '3': 2, '4': 1, '5': 9, '10': 'rowId'},
    const {'1': 'field_id', '3': 3, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'data', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'data'},
  ],
  '8': const [
    const {'1': 'one_of_data'},
  ],
};

/// Descriptor for `CellMetaChangeset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellMetaChangesetDescriptor = $convert.base64Decode('ChFDZWxsTWV0YUNoYW5nZXNldBIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSFQoGcm93X2lkGAIgASgJUgVyb3dJZBIZCghmaWVsZF9pZBgDIAEoCVIHZmllbGRJZBIUCgRkYXRhGAQgASgJSABSBGRhdGFCDQoLb25lX29mX2RhdGE=');
@$core.Deprecated('Use buildGridContextDescriptor instead')
const BuildGridContext$json = const {
  '1': 'BuildGridContext',
  '2': const [
    const {'1': 'field_metas', '3': 1, '4': 3, '5': 11, '6': '.FieldMeta', '10': 'fieldMetas'},
    const {'1': 'block_metas', '3': 2, '4': 1, '5': 11, '6': '.GridBlockMeta', '10': 'blockMetas'},
    const {'1': 'block_meta_data', '3': 3, '4': 1, '5': 11, '6': '.GridBlockMetaSerde', '10': 'blockMetaData'},
  ],
};

/// Descriptor for `BuildGridContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildGridContextDescriptor = $convert.base64Decode('ChBCdWlsZEdyaWRDb250ZXh0EisKC2ZpZWxkX21ldGFzGAEgAygLMgouRmllbGRNZXRhUgpmaWVsZE1ldGFzEi8KC2Jsb2NrX21ldGFzGAIgASgLMg4uR3JpZEJsb2NrTWV0YVIKYmxvY2tNZXRhcxI7Cg9ibG9ja19tZXRhX2RhdGEYAyABKAsyEy5HcmlkQmxvY2tNZXRhU2VyZGVSDWJsb2NrTWV0YURhdGE=');
