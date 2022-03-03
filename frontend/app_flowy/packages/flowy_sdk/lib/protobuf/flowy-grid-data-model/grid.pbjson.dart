///
//  Generated code. Do not modify.
//  source: grid.proto
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
@$core.Deprecated('Use gridDescriptor instead')
const Grid$json = const {
  '1': 'Grid',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'filters', '3': 2, '4': 1, '5': 11, '6': '.RepeatedGridFilter', '10': 'filters'},
    const {'1': 'field_orders', '3': 3, '4': 1, '5': 11, '6': '.RepeatedFieldOrder', '10': 'fieldOrders'},
    const {'1': 'row_orders', '3': 4, '4': 1, '5': 11, '6': '.RepeatedRowOrder', '10': 'rowOrders'},
  ],
};

/// Descriptor for `Grid`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridDescriptor = $convert.base64Decode('CgRHcmlkEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBItCgdmaWx0ZXJzGAIgASgLMhMuUmVwZWF0ZWRHcmlkRmlsdGVyUgdmaWx0ZXJzEjYKDGZpZWxkX29yZGVycxgDIAEoCzITLlJlcGVhdGVkRmllbGRPcmRlclILZmllbGRPcmRlcnMSMAoKcm93X29yZGVycxgEIAEoCzIRLlJlcGVhdGVkUm93T3JkZXJSCXJvd09yZGVycw==');
@$core.Deprecated('Use gridFilterDescriptor instead')
const GridFilter$json = const {
  '1': 'GridFilter',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
  ],
};

/// Descriptor for `GridFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridFilterDescriptor = $convert.base64Decode('CgpHcmlkRmlsdGVyEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2M=');
@$core.Deprecated('Use repeatedGridFilterDescriptor instead')
const RepeatedGridFilter$json = const {
  '1': 'RepeatedGridFilter',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.GridFilter', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedGridFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedGridFilterDescriptor = $convert.base64Decode('ChJSZXBlYXRlZEdyaWRGaWx0ZXISIQoFaXRlbXMYASADKAsyCy5HcmlkRmlsdGVyUgVpdGVtcw==');
@$core.Deprecated('Use fieldOrderDescriptor instead')
const FieldOrder$json = const {
  '1': 'FieldOrder',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'visibility', '3': 2, '4': 1, '5': 8, '10': 'visibility'},
    const {'1': 'width', '3': 3, '4': 1, '5': 5, '10': 'width'},
  ],
};

/// Descriptor for `FieldOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldOrderDescriptor = $convert.base64Decode('CgpGaWVsZE9yZGVyEhkKCGZpZWxkX2lkGAEgASgJUgdmaWVsZElkEh4KCnZpc2liaWxpdHkYAiABKAhSCnZpc2liaWxpdHkSFAoFd2lkdGgYAyABKAVSBXdpZHRo');
@$core.Deprecated('Use repeatedFieldOrderDescriptor instead')
const RepeatedFieldOrder$json = const {
  '1': 'RepeatedFieldOrder',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.FieldOrder', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedFieldOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedFieldOrderDescriptor = $convert.base64Decode('ChJSZXBlYXRlZEZpZWxkT3JkZXISIQoFaXRlbXMYASADKAsyCy5GaWVsZE9yZGVyUgVpdGVtcw==');
@$core.Deprecated('Use fieldDescriptor instead')
const Field$json = const {
  '1': 'Field',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'field_type', '3': 4, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'frozen', '3': 5, '4': 1, '5': 8, '10': 'frozen'},
    const {'1': 'type_options', '3': 6, '4': 1, '5': 11, '6': '.AnyData', '10': 'typeOptions'},
  ],
};

/// Descriptor for `Field`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldDescriptor = $convert.base64Decode('CgVGaWVsZBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEikKCmZpZWxkX3R5cGUYBCABKA4yCi5GaWVsZFR5cGVSCWZpZWxkVHlwZRIWCgZmcm96ZW4YBSABKAhSBmZyb3plbhIrCgx0eXBlX29wdGlvbnMYBiABKAsyCC5BbnlEYXRhUgt0eXBlT3B0aW9ucw==');
@$core.Deprecated('Use anyDataDescriptor instead')
const AnyData$json = const {
  '1': 'AnyData',
  '2': const [
    const {'1': 'type_url', '3': 1, '4': 1, '5': 9, '10': 'typeUrl'},
    const {'1': 'value', '3': 2, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `AnyData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List anyDataDescriptor = $convert.base64Decode('CgdBbnlEYXRhEhkKCHR5cGVfdXJsGAEgASgJUgd0eXBlVXJsEhQKBXZhbHVlGAIgASgMUgV2YWx1ZQ==');
@$core.Deprecated('Use rowOrderDescriptor instead')
const RowOrder$json = const {
  '1': 'RowOrder',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'row_id', '3': 2, '4': 1, '5': 9, '10': 'rowId'},
    const {'1': 'visibility', '3': 3, '4': 1, '5': 8, '10': 'visibility'},
  ],
};

/// Descriptor for `RowOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowOrderDescriptor = $convert.base64Decode('CghSb3dPcmRlchIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSFQoGcm93X2lkGAIgASgJUgVyb3dJZBIeCgp2aXNpYmlsaXR5GAMgASgIUgp2aXNpYmlsaXR5');
@$core.Deprecated('Use repeatedRowOrderDescriptor instead')
const RepeatedRowOrder$json = const {
  '1': 'RepeatedRowOrder',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.RowOrder', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedRowOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedRowOrderDescriptor = $convert.base64Decode('ChBSZXBlYXRlZFJvd09yZGVyEh8KBWl0ZW1zGAEgAygLMgkuUm93T3JkZXJSBWl0ZW1z');
@$core.Deprecated('Use rowDescriptor instead')
const Row$json = const {
  '1': 'Row',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'modified_time', '3': 3, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'cell_by_field_id', '3': 4, '4': 3, '5': 11, '6': '.Row.CellByFieldIdEntry', '10': 'cellByFieldId'},
  ],
  '3': const [Row_CellByFieldIdEntry$json],
};

@$core.Deprecated('Use rowDescriptor instead')
const Row_CellByFieldIdEntry$json = const {
  '1': 'CellByFieldIdEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.Cell', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `Row`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowDescriptor = $convert.base64Decode('CgNSb3cSDgoCaWQYASABKAlSAmlkEhcKB2dyaWRfaWQYAiABKAlSBmdyaWRJZBIjCg1tb2RpZmllZF90aW1lGAMgASgDUgxtb2RpZmllZFRpbWUSQAoQY2VsbF9ieV9maWVsZF9pZBgEIAMoCzIXLlJvdy5DZWxsQnlGaWVsZElkRW50cnlSDWNlbGxCeUZpZWxkSWQaRwoSQ2VsbEJ5RmllbGRJZEVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhsKBXZhbHVlGAIgASgLMgUuQ2VsbFIFdmFsdWU6AjgB');
@$core.Deprecated('Use cellDescriptor instead')
const Cell$json = const {
  '1': 'Cell',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'row_id', '3': 2, '4': 1, '5': 9, '10': 'rowId'},
    const {'1': 'field_id', '3': 3, '4': 1, '5': 9, '10': 'fieldId'},
  ],
};

/// Descriptor for `Cell`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellDescriptor = $convert.base64Decode('CgRDZWxsEg4KAmlkGAEgASgJUgJpZBIVCgZyb3dfaWQYAiABKAlSBXJvd0lkEhkKCGZpZWxkX2lkGAMgASgJUgdmaWVsZElk');
@$core.Deprecated('Use displayCellDescriptor instead')
const DisplayCell$json = const {
  '1': 'DisplayCell',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `DisplayCell`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List displayCellDescriptor = $convert.base64Decode('CgtEaXNwbGF5Q2VsbBIOCgJpZBgBIAEoCVICaWQSGAoHY29udGVudBgCIAEoCVIHY29udGVudA==');
@$core.Deprecated('Use rawCellDescriptor instead')
const RawCell$json = const {
  '1': 'RawCell',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'data', '3': 2, '4': 1, '5': 11, '6': '.AnyData', '10': 'data'},
  ],
};

/// Descriptor for `RawCell`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rawCellDescriptor = $convert.base64Decode('CgdSYXdDZWxsEg4KAmlkGAEgASgJUgJpZBIcCgRkYXRhGAIgASgLMgguQW55RGF0YVIEZGF0YQ==');
@$core.Deprecated('Use createGridPayloadDescriptor instead')
const CreateGridPayload$json = const {
  '1': 'CreateGridPayload',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `CreateGridPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createGridPayloadDescriptor = $convert.base64Decode('ChFDcmVhdGVHcmlkUGF5bG9hZBISCgRuYW1lGAEgASgJUgRuYW1l');
@$core.Deprecated('Use gridIdDescriptor instead')
const GridId$json = const {
  '1': 'GridId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `GridId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridIdDescriptor = $convert.base64Decode('CgZHcmlkSWQSFAoFdmFsdWUYASABKAlSBXZhbHVl');
