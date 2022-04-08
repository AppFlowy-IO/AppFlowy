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
@$core.Deprecated('Use gridBlockMetaDataDescriptor instead')
const GridBlockMetaData$json = const {
  '1': 'GridBlockMetaData',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'row_metas', '3': 2, '4': 3, '5': 11, '6': '.RowMeta', '10': 'rowMetas'},
  ],
};

/// Descriptor for `GridBlockMetaData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridBlockMetaDataDescriptor = $convert.base64Decode('ChFHcmlkQmxvY2tNZXRhRGF0YRIZCghibG9ja19pZBgBIAEoCVIHYmxvY2tJZBIlCglyb3dfbWV0YXMYAiADKAsyCC5Sb3dNZXRhUghyb3dNZXRhcw==');
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
    const {'1': 'type_options', '3': 8, '4': 3, '5': 11, '6': '.FieldMeta.TypeOptionsEntry', '10': 'typeOptions'},
  ],
  '3': const [FieldMeta_TypeOptionsEntry$json],
};

@$core.Deprecated('Use fieldMetaDescriptor instead')
const FieldMeta_TypeOptionsEntry$json = const {
  '1': 'TypeOptionsEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `FieldMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldMetaDescriptor = $convert.base64Decode('CglGaWVsZE1ldGESDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSEgoEZGVzYxgDIAEoCVIEZGVzYxIpCgpmaWVsZF90eXBlGAQgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGUSFgoGZnJvemVuGAUgASgIUgZmcm96ZW4SHgoKdmlzaWJpbGl0eRgGIAEoCFIKdmlzaWJpbGl0eRIUCgV3aWR0aBgHIAEoBVIFd2lkdGgSPgoMdHlwZV9vcHRpb25zGAggAygLMhsuRmllbGRNZXRhLlR5cGVPcHRpb25zRW50cnlSC3R5cGVPcHRpb25zGj4KEFR5cGVPcHRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');
@$core.Deprecated('Use fieldChangesetPayloadDescriptor instead')
const FieldChangesetPayload$json = const {
  '1': 'FieldChangesetPayload',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'field_type', '3': 5, '4': 1, '5': 14, '6': '.FieldType', '9': 2, '10': 'fieldType'},
    const {'1': 'frozen', '3': 6, '4': 1, '5': 8, '9': 3, '10': 'frozen'},
    const {'1': 'visibility', '3': 7, '4': 1, '5': 8, '9': 4, '10': 'visibility'},
    const {'1': 'width', '3': 8, '4': 1, '5': 5, '9': 5, '10': 'width'},
    const {'1': 'type_option_data', '3': 9, '4': 1, '5': 12, '9': 6, '10': 'typeOptionData'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_field_type'},
    const {'1': 'one_of_frozen'},
    const {'1': 'one_of_visibility'},
    const {'1': 'one_of_width'},
    const {'1': 'one_of_type_option_data'},
  ],
};

/// Descriptor for `FieldChangesetPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldChangesetPayloadDescriptor = $convert.base64Decode('ChVGaWVsZENoYW5nZXNldFBheWxvYWQSGQoIZmllbGRfaWQYASABKAlSB2ZpZWxkSWQSFwoHZ3JpZF9pZBgCIAEoCVIGZ3JpZElkEhQKBG5hbWUYAyABKAlIAFIEbmFtZRIUCgRkZXNjGAQgASgJSAFSBGRlc2MSKwoKZmllbGRfdHlwZRgFIAEoDjIKLkZpZWxkVHlwZUgCUglmaWVsZFR5cGUSGAoGZnJvemVuGAYgASgISANSBmZyb3plbhIgCgp2aXNpYmlsaXR5GAcgASgISARSCnZpc2liaWxpdHkSFgoFd2lkdGgYCCABKAVIBVIFd2lkdGgSKgoQdHlwZV9vcHRpb25fZGF0YRgJIAEoDEgGUg50eXBlT3B0aW9uRGF0YUINCgtvbmVfb2ZfbmFtZUINCgtvbmVfb2ZfZGVzY0ITChFvbmVfb2ZfZmllbGRfdHlwZUIPCg1vbmVfb2ZfZnJvemVuQhMKEW9uZV9vZl92aXNpYmlsaXR5Qg4KDG9uZV9vZl93aWR0aEIZChdvbmVfb2ZfdHlwZV9vcHRpb25fZGF0YQ==');
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
    const {'1': 'cells', '3': 3, '4': 3, '5': 11, '6': '.RowMeta.CellsEntry', '10': 'cells'},
    const {'1': 'height', '3': 4, '4': 1, '5': 5, '10': 'height'},
    const {'1': 'visibility', '3': 5, '4': 1, '5': 8, '10': 'visibility'},
  ],
  '3': const [RowMeta_CellsEntry$json],
};

@$core.Deprecated('Use rowMetaDescriptor instead')
const RowMeta_CellsEntry$json = const {
  '1': 'CellsEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.CellMeta', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `RowMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowMetaDescriptor = $convert.base64Decode('CgdSb3dNZXRhEg4KAmlkGAEgASgJUgJpZBIZCghibG9ja19pZBgCIAEoCVIHYmxvY2tJZBIpCgVjZWxscxgDIAMoCzITLlJvd01ldGEuQ2VsbHNFbnRyeVIFY2VsbHMSFgoGaGVpZ2h0GAQgASgFUgZoZWlnaHQSHgoKdmlzaWJpbGl0eRgFIAEoCFIKdmlzaWJpbGl0eRpDCgpDZWxsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5Eh8KBXZhbHVlGAIgASgLMgkuQ2VsbE1ldGFSBXZhbHVlOgI4AQ==');
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
    const {'1': 'data', '3': 1, '4': 1, '5': 9, '10': 'data'},
  ],
};

/// Descriptor for `CellMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellMetaDescriptor = $convert.base64Decode('CghDZWxsTWV0YRISCgRkYXRhGAEgASgJUgRkYXRh');
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
    const {'1': 'block_meta_data', '3': 3, '4': 1, '5': 11, '6': '.GridBlockMetaData', '10': 'blockMetaData'},
  ],
};

/// Descriptor for `BuildGridContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildGridContextDescriptor = $convert.base64Decode('ChBCdWlsZEdyaWRDb250ZXh0EisKC2ZpZWxkX21ldGFzGAEgAygLMgouRmllbGRNZXRhUgpmaWVsZE1ldGFzEi8KC2Jsb2NrX21ldGFzGAIgASgLMg4uR3JpZEJsb2NrTWV0YVIKYmxvY2tNZXRhcxI6Cg9ibG9ja19tZXRhX2RhdGEYAyABKAsyEi5HcmlkQmxvY2tNZXRhRGF0YVINYmxvY2tNZXRhRGF0YQ==');
