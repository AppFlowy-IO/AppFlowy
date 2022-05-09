///
//  Generated code. Do not modify.
//  source: grid.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use moveItemTypeDescriptor instead')
const MoveItemType$json = const {
  '1': 'MoveItemType',
  '2': const [
    const {'1': 'MoveField', '2': 0},
    const {'1': 'MoveRow', '2': 1},
  ],
};

/// Descriptor for `MoveItemType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List moveItemTypeDescriptor = $convert.base64Decode('CgxNb3ZlSXRlbVR5cGUSDQoJTW92ZUZpZWxkEAASCwoHTW92ZVJvdxAB');
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
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'field_orders', '3': 2, '4': 3, '5': 11, '6': '.FieldOrder', '10': 'fieldOrders'},
    const {'1': 'block_orders', '3': 3, '4': 3, '5': 11, '6': '.GridBlockOrder', '10': 'blockOrders'},
  ],
};

/// Descriptor for `Grid`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridDescriptor = $convert.base64Decode('CgRHcmlkEg4KAmlkGAEgASgJUgJpZBIuCgxmaWVsZF9vcmRlcnMYAiADKAsyCy5GaWVsZE9yZGVyUgtmaWVsZE9yZGVycxIyCgxibG9ja19vcmRlcnMYAyADKAsyDy5HcmlkQmxvY2tPcmRlclILYmxvY2tPcmRlcnM=');
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
    const {'1': 'is_primary', '3': 8, '4': 1, '5': 8, '10': 'isPrimary'},
  ],
};

/// Descriptor for `Field`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldDescriptor = $convert.base64Decode('CgVGaWVsZBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEikKCmZpZWxkX3R5cGUYBCABKA4yCi5GaWVsZFR5cGVSCWZpZWxkVHlwZRIWCgZmcm96ZW4YBSABKAhSBmZyb3plbhIeCgp2aXNpYmlsaXR5GAYgASgIUgp2aXNpYmlsaXR5EhQKBXdpZHRoGAcgASgFUgV3aWR0aBIdCgppc19wcmltYXJ5GAggASgIUglpc1ByaW1hcnk=');
@$core.Deprecated('Use fieldOrderDescriptor instead')
const FieldOrder$json = const {
  '1': 'FieldOrder',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
  ],
};

/// Descriptor for `FieldOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldOrderDescriptor = $convert.base64Decode('CgpGaWVsZE9yZGVyEhkKCGZpZWxkX2lkGAEgASgJUgdmaWVsZElk');
@$core.Deprecated('Use gridFieldChangesetDescriptor instead')
const GridFieldChangeset$json = const {
  '1': 'GridFieldChangeset',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'inserted_fields', '3': 2, '4': 3, '5': 11, '6': '.IndexField', '10': 'insertedFields'},
    const {'1': 'deleted_fields', '3': 3, '4': 3, '5': 11, '6': '.FieldOrder', '10': 'deletedFields'},
    const {'1': 'updated_fields', '3': 4, '4': 3, '5': 11, '6': '.Field', '10': 'updatedFields'},
  ],
};

/// Descriptor for `GridFieldChangeset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridFieldChangesetDescriptor = $convert.base64Decode('ChJHcmlkRmllbGRDaGFuZ2VzZXQSFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEjQKD2luc2VydGVkX2ZpZWxkcxgCIAMoCzILLkluZGV4RmllbGRSDmluc2VydGVkRmllbGRzEjIKDmRlbGV0ZWRfZmllbGRzGAMgAygLMgsuRmllbGRPcmRlclINZGVsZXRlZEZpZWxkcxItCg51cGRhdGVkX2ZpZWxkcxgEIAMoCzIGLkZpZWxkUg11cGRhdGVkRmllbGRz');
@$core.Deprecated('Use indexFieldDescriptor instead')
const IndexField$json = const {
  '1': 'IndexField',
  '2': const [
    const {'1': 'field', '3': 1, '4': 1, '5': 11, '6': '.Field', '10': 'field'},
    const {'1': 'index', '3': 2, '4': 1, '5': 5, '10': 'index'},
  ],
};

/// Descriptor for `IndexField`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexFieldDescriptor = $convert.base64Decode('CgpJbmRleEZpZWxkEhwKBWZpZWxkGAEgASgLMgYuRmllbGRSBWZpZWxkEhQKBWluZGV4GAIgASgFUgVpbmRleA==');
@$core.Deprecated('Use getEditFieldContextPayloadDescriptor instead')
const GetEditFieldContextPayload$json = const {
  '1': 'GetEditFieldContextPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
  ],
  '8': const [
    const {'1': 'one_of_field_id'},
  ],
};

/// Descriptor for `GetEditFieldContextPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEditFieldContextPayloadDescriptor = $convert.base64Decode('ChpHZXRFZGl0RmllbGRDb250ZXh0UGF5bG9hZBIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSGwoIZmllbGRfaWQYAiABKAlIAFIHZmllbGRJZBIpCgpmaWVsZF90eXBlGAMgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGVCEQoPb25lX29mX2ZpZWxkX2lk');
@$core.Deprecated('Use editFieldPayloadDescriptor instead')
const EditFieldPayload$json = const {
  '1': 'EditFieldPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
  ],
  '8': const [
    const {'1': 'one_of_field_id'},
  ],
};

/// Descriptor for `EditFieldPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editFieldPayloadDescriptor = $convert.base64Decode('ChBFZGl0RmllbGRQYXlsb2FkEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIbCghmaWVsZF9pZBgCIAEoCUgAUgdmaWVsZElkEikKCmZpZWxkX3R5cGUYAyABKA4yCi5GaWVsZFR5cGVSCWZpZWxkVHlwZUIRCg9vbmVfb2ZfZmllbGRfaWQ=');
@$core.Deprecated('Use editFieldContextDescriptor instead')
const EditFieldContext$json = const {
  '1': 'EditFieldContext',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'grid_field', '3': 2, '4': 1, '5': 11, '6': '.Field', '10': 'gridField'},
    const {'1': 'type_option_data', '3': 3, '4': 1, '5': 12, '10': 'typeOptionData'},
  ],
};

/// Descriptor for `EditFieldContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editFieldContextDescriptor = $convert.base64Decode('ChBFZGl0RmllbGRDb250ZXh0EhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIlCgpncmlkX2ZpZWxkGAIgASgLMgYuRmllbGRSCWdyaWRGaWVsZBIoChB0eXBlX29wdGlvbl9kYXRhGAMgASgMUg50eXBlT3B0aW9uRGF0YQ==');
@$core.Deprecated('Use fieldTypeOptionDataDescriptor instead')
const FieldTypeOptionData$json = const {
  '1': 'FieldTypeOptionData',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'type_option_data', '3': 2, '4': 1, '5': 12, '10': 'typeOptionData'},
  ],
};

/// Descriptor for `FieldTypeOptionData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldTypeOptionDataDescriptor = $convert.base64Decode('ChNGaWVsZFR5cGVPcHRpb25EYXRhEhkKCGZpZWxkX2lkGAEgASgJUgdmaWVsZElkEigKEHR5cGVfb3B0aW9uX2RhdGEYAiABKAxSDnR5cGVPcHRpb25EYXRh');
@$core.Deprecated('Use repeatedFieldDescriptor instead')
const RepeatedField$json = const {
  '1': 'RepeatedField',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.Field', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedField`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedFieldDescriptor = $convert.base64Decode('Cg1SZXBlYXRlZEZpZWxkEhwKBWl0ZW1zGAEgAygLMgYuRmllbGRSBWl0ZW1z');
@$core.Deprecated('Use repeatedFieldOrderDescriptor instead')
const RepeatedFieldOrder$json = const {
  '1': 'RepeatedFieldOrder',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.FieldOrder', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedFieldOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedFieldOrderDescriptor = $convert.base64Decode('ChJSZXBlYXRlZEZpZWxkT3JkZXISIQoFaXRlbXMYASADKAsyCy5GaWVsZE9yZGVyUgVpdGVtcw==');
@$core.Deprecated('Use rowOrderDescriptor instead')
const RowOrder$json = const {
  '1': 'RowOrder',
  '2': const [
    const {'1': 'row_id', '3': 1, '4': 1, '5': 9, '10': 'rowId'},
    const {'1': 'block_id', '3': 2, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'height', '3': 3, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `RowOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowOrderDescriptor = $convert.base64Decode('CghSb3dPcmRlchIVCgZyb3dfaWQYASABKAlSBXJvd0lkEhkKCGJsb2NrX2lkGAIgASgJUgdibG9ja0lkEhYKBmhlaWdodBgDIAEoBVIGaGVpZ2h0');
@$core.Deprecated('Use rowDescriptor instead')
const Row$json = const {
  '1': 'Row',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'cell_by_field_id', '3': 2, '4': 3, '5': 11, '6': '.Row.CellByFieldIdEntry', '10': 'cellByFieldId'},
    const {'1': 'height', '3': 3, '4': 1, '5': 5, '10': 'height'},
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
final $typed_data.Uint8List rowDescriptor = $convert.base64Decode('CgNSb3cSDgoCaWQYASABKAlSAmlkEkAKEGNlbGxfYnlfZmllbGRfaWQYAiADKAsyFy5Sb3cuQ2VsbEJ5RmllbGRJZEVudHJ5Ug1jZWxsQnlGaWVsZElkEhYKBmhlaWdodBgDIAEoBVIGaGVpZ2h0GkcKEkNlbGxCeUZpZWxkSWRFbnRyeRIQCgNrZXkYASABKAlSA2tleRIbCgV2YWx1ZRgCIAEoCzIFLkNlbGxSBXZhbHVlOgI4AQ==');
@$core.Deprecated('Use repeatedRowDescriptor instead')
const RepeatedRow$json = const {
  '1': 'RepeatedRow',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.Row', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedRowDescriptor = $convert.base64Decode('CgtSZXBlYXRlZFJvdxIaCgVpdGVtcxgBIAMoCzIELlJvd1IFaXRlbXM=');
@$core.Deprecated('Use repeatedGridBlockDescriptor instead')
const RepeatedGridBlock$json = const {
  '1': 'RepeatedGridBlock',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.GridBlock', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedGridBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedGridBlockDescriptor = $convert.base64Decode('ChFSZXBlYXRlZEdyaWRCbG9jaxIgCgVpdGVtcxgBIAMoCzIKLkdyaWRCbG9ja1IFaXRlbXM=');
@$core.Deprecated('Use gridBlockOrderDescriptor instead')
const GridBlockOrder$json = const {
  '1': 'GridBlockOrder',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'row_orders', '3': 2, '4': 3, '5': 11, '6': '.RowOrder', '10': 'rowOrders'},
  ],
};

/// Descriptor for `GridBlockOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridBlockOrderDescriptor = $convert.base64Decode('Cg5HcmlkQmxvY2tPcmRlchIZCghibG9ja19pZBgBIAEoCVIHYmxvY2tJZBIoCgpyb3dfb3JkZXJzGAIgAygLMgkuUm93T3JkZXJSCXJvd09yZGVycw==');
@$core.Deprecated('Use indexRowOrderDescriptor instead')
const IndexRowOrder$json = const {
  '1': 'IndexRowOrder',
  '2': const [
    const {'1': 'row_order', '3': 1, '4': 1, '5': 11, '6': '.RowOrder', '10': 'rowOrder'},
    const {'1': 'index', '3': 2, '4': 1, '5': 5, '9': 0, '10': 'index'},
  ],
  '8': const [
    const {'1': 'one_of_index'},
  ],
};

/// Descriptor for `IndexRowOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexRowOrderDescriptor = $convert.base64Decode('Cg1JbmRleFJvd09yZGVyEiYKCXJvd19vcmRlchgBIAEoCzIJLlJvd09yZGVyUghyb3dPcmRlchIWCgVpbmRleBgCIAEoBUgAUgVpbmRleEIOCgxvbmVfb2ZfaW5kZXg=');
@$core.Deprecated('Use updatedRowOrderDescriptor instead')
const UpdatedRowOrder$json = const {
  '1': 'UpdatedRowOrder',
  '2': const [
    const {'1': 'row_order', '3': 1, '4': 1, '5': 11, '6': '.RowOrder', '10': 'rowOrder'},
    const {'1': 'row', '3': 2, '4': 1, '5': 11, '6': '.Row', '10': 'row'},
  ],
};

/// Descriptor for `UpdatedRowOrder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatedRowOrderDescriptor = $convert.base64Decode('Cg9VcGRhdGVkUm93T3JkZXISJgoJcm93X29yZGVyGAEgASgLMgkuUm93T3JkZXJSCHJvd09yZGVyEhYKA3JvdxgCIAEoCzIELlJvd1IDcm93');
@$core.Deprecated('Use gridRowsChangesetDescriptor instead')
const GridRowsChangeset$json = const {
  '1': 'GridRowsChangeset',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'inserted_rows', '3': 2, '4': 3, '5': 11, '6': '.IndexRowOrder', '10': 'insertedRows'},
    const {'1': 'deleted_rows', '3': 3, '4': 3, '5': 11, '6': '.RowOrder', '10': 'deletedRows'},
    const {'1': 'updated_rows', '3': 4, '4': 3, '5': 11, '6': '.UpdatedRowOrder', '10': 'updatedRows'},
  ],
};

/// Descriptor for `GridRowsChangeset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridRowsChangesetDescriptor = $convert.base64Decode('ChFHcmlkUm93c0NoYW5nZXNldBIZCghibG9ja19pZBgBIAEoCVIHYmxvY2tJZBIzCg1pbnNlcnRlZF9yb3dzGAIgAygLMg4uSW5kZXhSb3dPcmRlclIMaW5zZXJ0ZWRSb3dzEiwKDGRlbGV0ZWRfcm93cxgDIAMoCzIJLlJvd09yZGVyUgtkZWxldGVkUm93cxIzCgx1cGRhdGVkX3Jvd3MYBCADKAsyEC5VcGRhdGVkUm93T3JkZXJSC3VwZGF0ZWRSb3dz');
@$core.Deprecated('Use gridBlockDescriptor instead')
const GridBlock$json = const {
  '1': 'GridBlock',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'row_orders', '3': 2, '4': 3, '5': 11, '6': '.RowOrder', '10': 'rowOrders'},
  ],
};

/// Descriptor for `GridBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridBlockDescriptor = $convert.base64Decode('CglHcmlkQmxvY2sSDgoCaWQYASABKAlSAmlkEigKCnJvd19vcmRlcnMYAiADKAsyCS5Sb3dPcmRlclIJcm93T3JkZXJz');
@$core.Deprecated('Use cellDescriptor instead')
const Cell$json = const {
  '1': 'Cell',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `Cell`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellDescriptor = $convert.base64Decode('CgRDZWxsEhkKCGZpZWxkX2lkGAEgASgJUgdmaWVsZElkEhgKB2NvbnRlbnQYAiABKAlSB2NvbnRlbnQ=');
@$core.Deprecated('Use repeatedCellDescriptor instead')
const RepeatedCell$json = const {
  '1': 'RepeatedCell',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.Cell', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedCell`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedCellDescriptor = $convert.base64Decode('CgxSZXBlYXRlZENlbGwSGwoFaXRlbXMYASADKAsyBS5DZWxsUgVpdGVtcw==');
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
@$core.Deprecated('Use gridBlockIdDescriptor instead')
const GridBlockId$json = const {
  '1': 'GridBlockId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `GridBlockId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridBlockIdDescriptor = $convert.base64Decode('CgtHcmlkQmxvY2tJZBIUCgV2YWx1ZRgBIAEoCVIFdmFsdWU=');
@$core.Deprecated('Use createRowPayloadDescriptor instead')
const CreateRowPayload$json = const {
  '1': 'CreateRowPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'start_row_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'startRowId'},
  ],
  '8': const [
    const {'1': 'one_of_start_row_id'},
  ],
};

/// Descriptor for `CreateRowPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createRowPayloadDescriptor = $convert.base64Decode('ChBDcmVhdGVSb3dQYXlsb2FkEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIiCgxzdGFydF9yb3dfaWQYAiABKAlIAFIKc3RhcnRSb3dJZEIVChNvbmVfb2Zfc3RhcnRfcm93X2lk');
@$core.Deprecated('Use insertFieldPayloadDescriptor instead')
const InsertFieldPayload$json = const {
  '1': 'InsertFieldPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field', '3': 2, '4': 1, '5': 11, '6': '.Field', '10': 'field'},
    const {'1': 'type_option_data', '3': 3, '4': 1, '5': 12, '10': 'typeOptionData'},
    const {'1': 'start_field_id', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'startFieldId'},
  ],
  '8': const [
    const {'1': 'one_of_start_field_id'},
  ],
};

/// Descriptor for `InsertFieldPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List insertFieldPayloadDescriptor = $convert.base64Decode('ChJJbnNlcnRGaWVsZFBheWxvYWQSFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEhwKBWZpZWxkGAIgASgLMgYuRmllbGRSBWZpZWxkEigKEHR5cGVfb3B0aW9uX2RhdGEYAyABKAxSDnR5cGVPcHRpb25EYXRhEiYKDnN0YXJ0X2ZpZWxkX2lkGAQgASgJSABSDHN0YXJ0RmllbGRJZEIXChVvbmVfb2Zfc3RhcnRfZmllbGRfaWQ=');
@$core.Deprecated('Use queryFieldPayloadDescriptor instead')
const QueryFieldPayload$json = const {
  '1': 'QueryFieldPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_orders', '3': 2, '4': 1, '5': 11, '6': '.RepeatedFieldOrder', '10': 'fieldOrders'},
  ],
};

/// Descriptor for `QueryFieldPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryFieldPayloadDescriptor = $convert.base64Decode('ChFRdWVyeUZpZWxkUGF5bG9hZBIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSNgoMZmllbGRfb3JkZXJzGAIgASgLMhMuUmVwZWF0ZWRGaWVsZE9yZGVyUgtmaWVsZE9yZGVycw==');
@$core.Deprecated('Use queryGridBlocksPayloadDescriptor instead')
const QueryGridBlocksPayload$json = const {
  '1': 'QueryGridBlocksPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'block_orders', '3': 2, '4': 3, '5': 11, '6': '.GridBlockOrder', '10': 'blockOrders'},
  ],
};

/// Descriptor for `QueryGridBlocksPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryGridBlocksPayloadDescriptor = $convert.base64Decode('ChZRdWVyeUdyaWRCbG9ja3NQYXlsb2FkEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIyCgxibG9ja19vcmRlcnMYAiADKAsyDy5HcmlkQmxvY2tPcmRlclILYmxvY2tPcmRlcnM=');
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
@$core.Deprecated('Use moveItemPayloadDescriptor instead')
const MoveItemPayload$json = const {
  '1': 'MoveItemPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'item_id', '3': 2, '4': 1, '5': 9, '10': 'itemId'},
    const {'1': 'from_index', '3': 3, '4': 1, '5': 5, '10': 'fromIndex'},
    const {'1': 'to_index', '3': 4, '4': 1, '5': 5, '10': 'toIndex'},
    const {'1': 'ty', '3': 5, '4': 1, '5': 14, '6': '.MoveItemType', '10': 'ty'},
  ],
};

/// Descriptor for `MoveItemPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveItemPayloadDescriptor = $convert.base64Decode('Cg9Nb3ZlSXRlbVBheWxvYWQSFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEhcKB2l0ZW1faWQYAiABKAlSBml0ZW1JZBIdCgpmcm9tX2luZGV4GAMgASgFUglmcm9tSW5kZXgSGQoIdG9faW5kZXgYBCABKAVSB3RvSW5kZXgSHQoCdHkYBSABKA4yDS5Nb3ZlSXRlbVR5cGVSAnR5');
@$core.Deprecated('Use cellChangesetDescriptor instead')
const CellChangeset$json = const {
  '1': 'CellChangeset',
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

/// Descriptor for `CellChangeset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellChangesetDescriptor = $convert.base64Decode('Cg1DZWxsQ2hhbmdlc2V0EhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIVCgZyb3dfaWQYAiABKAlSBXJvd0lkEhkKCGZpZWxkX2lkGAMgASgJUgdmaWVsZElkEhQKBGRhdGEYBCABKAlIAFIEZGF0YUINCgtvbmVfb2ZfZGF0YQ==');
