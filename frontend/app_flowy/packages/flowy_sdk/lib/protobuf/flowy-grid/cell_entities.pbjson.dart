///
//  Generated code. Do not modify.
//  source: cell_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createSelectOptionPayloadPBDescriptor instead')
const CreateSelectOptionPayloadPB$json = const {
  '1': 'CreateSelectOptionPayloadPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'option_name', '3': 3, '4': 1, '5': 9, '10': 'optionName'},
  ],
};

/// Descriptor for `CreateSelectOptionPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSelectOptionPayloadPBDescriptor = $convert.base64Decode('ChtDcmVhdGVTZWxlY3RPcHRpb25QYXlsb2FkUEISGQoIZmllbGRfaWQYASABKAlSB2ZpZWxkSWQSFwoHZ3JpZF9pZBgCIAEoCVIGZ3JpZElkEh8KC29wdGlvbl9uYW1lGAMgASgJUgpvcHRpb25OYW1l');
@$core.Deprecated('Use cellPathPBDescriptor instead')
const CellPathPB$json = const {
  '1': 'CellPathPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'row_id', '3': 3, '4': 1, '5': 9, '10': 'rowId'},
  ],
};

/// Descriptor for `CellPathPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellPathPBDescriptor = $convert.base64Decode('CgpDZWxsUGF0aFBCEhcKB3ZpZXdfaWQYASABKAlSBnZpZXdJZBIZCghmaWVsZF9pZBgCIAEoCVIHZmllbGRJZBIVCgZyb3dfaWQYAyABKAlSBXJvd0lk');
@$core.Deprecated('Use cellPBDescriptor instead')
const CellPB$json = const {
  '1': 'CellPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '9': 0, '10': 'fieldType'},
  ],
  '8': const [
    const {'1': 'one_of_field_type'},
  ],
};

/// Descriptor for `CellPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellPBDescriptor = $convert.base64Decode('CgZDZWxsUEISGQoIZmllbGRfaWQYASABKAlSB2ZpZWxkSWQSEgoEZGF0YRgCIAEoDFIEZGF0YRIrCgpmaWVsZF90eXBlGAMgASgOMgouRmllbGRUeXBlSABSCWZpZWxkVHlwZUITChFvbmVfb2ZfZmllbGRfdHlwZQ==');
@$core.Deprecated('Use repeatedCellPBDescriptor instead')
const RepeatedCellPB$json = const {
  '1': 'RepeatedCellPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.CellPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedCellPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedCellPBDescriptor = $convert.base64Decode('Cg5SZXBlYXRlZENlbGxQQhIdCgVpdGVtcxgBIAMoCzIHLkNlbGxQQlIFaXRlbXM=');
@$core.Deprecated('Use cellChangesetPBDescriptor instead')
const CellChangesetPB$json = const {
  '1': 'CellChangesetPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'row_id', '3': 2, '4': 1, '5': 9, '10': 'rowId'},
    const {'1': 'field_id', '3': 3, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'type_cell_data', '3': 4, '4': 1, '5': 9, '10': 'typeCellData'},
  ],
};

/// Descriptor for `CellChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellChangesetPBDescriptor = $convert.base64Decode('Cg9DZWxsQ2hhbmdlc2V0UEISFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEhUKBnJvd19pZBgCIAEoCVIFcm93SWQSGQoIZmllbGRfaWQYAyABKAlSB2ZpZWxkSWQSJAoOdHlwZV9jZWxsX2RhdGEYBCABKAlSDHR5cGVDZWxsRGF0YQ==');
