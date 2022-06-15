///
//  Generated code. Do not modify.
//  source: field.proto
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
    const {'1': 'URL', '2': 6},
  ],
};

/// Descriptor for `FieldType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fieldTypeDescriptor = $convert.base64Decode('CglGaWVsZFR5cGUSDAoIUmljaFRleHQQABIKCgZOdW1iZXIQARIMCghEYXRlVGltZRACEhAKDFNpbmdsZVNlbGVjdBADEg8KC011bHRpU2VsZWN0EAQSDAoIQ2hlY2tib3gQBRIHCgNVUkwQBg==');
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
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'create_if_not_exist', '3': 4, '4': 1, '5': 8, '10': 'createIfNotExist'},
  ],
};

/// Descriptor for `EditFieldPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editFieldPayloadDescriptor = $convert.base64Decode('ChBFZGl0RmllbGRQYXlsb2FkEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIZCghmaWVsZF9pZBgCIAEoCVIHZmllbGRJZBIpCgpmaWVsZF90eXBlGAMgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGUSLQoTY3JlYXRlX2lmX25vdF9leGlzdBgEIAEoCFIQY3JlYXRlSWZOb3RFeGlzdA==');
@$core.Deprecated('Use fieldTypeOptionContextDescriptor instead')
const FieldTypeOptionContext$json = const {
  '1': 'FieldTypeOptionContext',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'grid_field', '3': 2, '4': 1, '5': 11, '6': '.Field', '10': 'gridField'},
    const {'1': 'type_option_data', '3': 3, '4': 1, '5': 12, '10': 'typeOptionData'},
  ],
};

/// Descriptor for `FieldTypeOptionContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldTypeOptionContextDescriptor = $convert.base64Decode('ChZGaWVsZFR5cGVPcHRpb25Db250ZXh0EhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIlCgpncmlkX2ZpZWxkGAIgASgLMgYuRmllbGRSCWdyaWRGaWVsZBIoChB0eXBlX29wdGlvbl9kYXRhGAMgASgMUg50eXBlT3B0aW9uRGF0YQ==');
@$core.Deprecated('Use fieldTypeOptionDataDescriptor instead')
const FieldTypeOptionData$json = const {
  '1': 'FieldTypeOptionData',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field', '3': 2, '4': 1, '5': 11, '6': '.Field', '10': 'field'},
    const {'1': 'type_option_data', '3': 3, '4': 1, '5': 12, '10': 'typeOptionData'},
  ],
};

/// Descriptor for `FieldTypeOptionData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldTypeOptionDataDescriptor = $convert.base64Decode('ChNGaWVsZFR5cGVPcHRpb25EYXRhEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIcCgVmaWVsZBgCIAEoCzIGLkZpZWxkUgVmaWVsZBIoChB0eXBlX29wdGlvbl9kYXRhGAMgASgMUg50eXBlT3B0aW9uRGF0YQ==');
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
@$core.Deprecated('Use updateFieldTypeOptionPayloadDescriptor instead')
const UpdateFieldTypeOptionPayload$json = const {
  '1': 'UpdateFieldTypeOptionPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'type_option_data', '3': 3, '4': 1, '5': 12, '10': 'typeOptionData'},
  ],
};

/// Descriptor for `UpdateFieldTypeOptionPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateFieldTypeOptionPayloadDescriptor = $convert.base64Decode('ChxVcGRhdGVGaWVsZFR5cGVPcHRpb25QYXlsb2FkEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIZCghmaWVsZF9pZBgCIAEoCVIHZmllbGRJZBIoChB0eXBlX29wdGlvbl9kYXRhGAMgASgMUg50eXBlT3B0aW9uRGF0YQ==');
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
