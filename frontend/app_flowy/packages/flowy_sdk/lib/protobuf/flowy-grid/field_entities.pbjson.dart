///
//  Generated code. Do not modify.
//  source: field_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

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
    const {'1': 'Checklist', '2': 7},
  ],
};

/// Descriptor for `FieldType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fieldTypeDescriptor = $convert.base64Decode('CglGaWVsZFR5cGUSDAoIUmljaFRleHQQABIKCgZOdW1iZXIQARIMCghEYXRlVGltZRACEhAKDFNpbmdsZVNlbGVjdBADEg8KC011bHRpU2VsZWN0EAQSDAoIQ2hlY2tib3gQBRIHCgNVUkwQBhINCglDaGVja2xpc3QQBw==');
@$core.Deprecated('Use fieldPBDescriptor instead')
const FieldPB$json = const {
  '1': 'FieldPB',
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

/// Descriptor for `FieldPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldPBDescriptor = $convert.base64Decode('CgdGaWVsZFBCEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2MSKQoKZmllbGRfdHlwZRgEIAEoDjIKLkZpZWxkVHlwZVIJZmllbGRUeXBlEhYKBmZyb3plbhgFIAEoCFIGZnJvemVuEh4KCnZpc2liaWxpdHkYBiABKAhSCnZpc2liaWxpdHkSFAoFd2lkdGgYByABKAVSBXdpZHRoEh0KCmlzX3ByaW1hcnkYCCABKAhSCWlzUHJpbWFyeQ==');
@$core.Deprecated('Use fieldIdPBDescriptor instead')
const FieldIdPB$json = const {
  '1': 'FieldIdPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
  ],
};

/// Descriptor for `FieldIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldIdPBDescriptor = $convert.base64Decode('CglGaWVsZElkUEISGQoIZmllbGRfaWQYASABKAlSB2ZpZWxkSWQ=');
@$core.Deprecated('Use gridFieldChangesetPBDescriptor instead')
const GridFieldChangesetPB$json = const {
  '1': 'GridFieldChangesetPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'inserted_fields', '3': 2, '4': 3, '5': 11, '6': '.IndexFieldPB', '10': 'insertedFields'},
    const {'1': 'deleted_fields', '3': 3, '4': 3, '5': 11, '6': '.FieldIdPB', '10': 'deletedFields'},
    const {'1': 'updated_fields', '3': 4, '4': 3, '5': 11, '6': '.FieldPB', '10': 'updatedFields'},
  ],
};

/// Descriptor for `GridFieldChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridFieldChangesetPBDescriptor = $convert.base64Decode('ChRHcmlkRmllbGRDaGFuZ2VzZXRQQhIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSNgoPaW5zZXJ0ZWRfZmllbGRzGAIgAygLMg0uSW5kZXhGaWVsZFBCUg5pbnNlcnRlZEZpZWxkcxIxCg5kZWxldGVkX2ZpZWxkcxgDIAMoCzIKLkZpZWxkSWRQQlINZGVsZXRlZEZpZWxkcxIvCg51cGRhdGVkX2ZpZWxkcxgEIAMoCzIILkZpZWxkUEJSDXVwZGF0ZWRGaWVsZHM=');
@$core.Deprecated('Use indexFieldPBDescriptor instead')
const IndexFieldPB$json = const {
  '1': 'IndexFieldPB',
  '2': const [
    const {'1': 'field', '3': 1, '4': 1, '5': 11, '6': '.FieldPB', '10': 'field'},
    const {'1': 'index', '3': 2, '4': 1, '5': 5, '10': 'index'},
  ],
};

/// Descriptor for `IndexFieldPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexFieldPBDescriptor = $convert.base64Decode('CgxJbmRleEZpZWxkUEISHgoFZmllbGQYASABKAsyCC5GaWVsZFBCUgVmaWVsZBIUCgVpbmRleBgCIAEoBVIFaW5kZXg=');
@$core.Deprecated('Use createFieldPayloadPBDescriptor instead')
const CreateFieldPayloadPB$json = const {
  '1': 'CreateFieldPayloadPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_type', '3': 2, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'type_option_data', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'typeOptionData'},
  ],
  '8': const [
    const {'1': 'one_of_type_option_data'},
  ],
};

/// Descriptor for `CreateFieldPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createFieldPayloadPBDescriptor = $convert.base64Decode('ChRDcmVhdGVGaWVsZFBheWxvYWRQQhIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSKQoKZmllbGRfdHlwZRgCIAEoDjIKLkZpZWxkVHlwZVIJZmllbGRUeXBlEioKEHR5cGVfb3B0aW9uX2RhdGEYAyABKAxIAFIOdHlwZU9wdGlvbkRhdGFCGQoXb25lX29mX3R5cGVfb3B0aW9uX2RhdGE=');
@$core.Deprecated('Use editFieldChangesetPBDescriptor instead')
const EditFieldChangesetPB$json = const {
  '1': 'EditFieldChangesetPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'create_if_not_exist', '3': 4, '4': 1, '5': 8, '10': 'createIfNotExist'},
  ],
};

/// Descriptor for `EditFieldChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editFieldChangesetPBDescriptor = $convert.base64Decode('ChRFZGl0RmllbGRDaGFuZ2VzZXRQQhIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSGQoIZmllbGRfaWQYAiABKAlSB2ZpZWxkSWQSKQoKZmllbGRfdHlwZRgDIAEoDjIKLkZpZWxkVHlwZVIJZmllbGRUeXBlEi0KE2NyZWF0ZV9pZl9ub3RfZXhpc3QYBCABKAhSEGNyZWF0ZUlmTm90RXhpc3Q=');
@$core.Deprecated('Use typeOptionPathPBDescriptor instead')
const TypeOptionPathPB$json = const {
  '1': 'TypeOptionPathPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
  ],
};

/// Descriptor for `TypeOptionPathPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typeOptionPathPBDescriptor = $convert.base64Decode('ChBUeXBlT3B0aW9uUGF0aFBCEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIZCghmaWVsZF9pZBgCIAEoCVIHZmllbGRJZBIpCgpmaWVsZF90eXBlGAMgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGU=');
@$core.Deprecated('Use typeOptionPBDescriptor instead')
const TypeOptionPB$json = const {
  '1': 'TypeOptionPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field', '3': 2, '4': 1, '5': 11, '6': '.FieldPB', '10': 'field'},
    const {'1': 'type_option_data', '3': 3, '4': 1, '5': 12, '10': 'typeOptionData'},
  ],
};

/// Descriptor for `TypeOptionPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typeOptionPBDescriptor = $convert.base64Decode('CgxUeXBlT3B0aW9uUEISFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEh4KBWZpZWxkGAIgASgLMgguRmllbGRQQlIFZmllbGQSKAoQdHlwZV9vcHRpb25fZGF0YRgDIAEoDFIOdHlwZU9wdGlvbkRhdGE=');
@$core.Deprecated('Use repeatedFieldPBDescriptor instead')
const RepeatedFieldPB$json = const {
  '1': 'RepeatedFieldPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.FieldPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedFieldPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedFieldPBDescriptor = $convert.base64Decode('Cg9SZXBlYXRlZEZpZWxkUEISHgoFaXRlbXMYASADKAsyCC5GaWVsZFBCUgVpdGVtcw==');
@$core.Deprecated('Use repeatedFieldIdPBDescriptor instead')
const RepeatedFieldIdPB$json = const {
  '1': 'RepeatedFieldIdPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.FieldIdPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedFieldIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedFieldIdPBDescriptor = $convert.base64Decode('ChFSZXBlYXRlZEZpZWxkSWRQQhIgCgVpdGVtcxgBIAMoCzIKLkZpZWxkSWRQQlIFaXRlbXM=');
@$core.Deprecated('Use typeOptionChangesetPBDescriptor instead')
const TypeOptionChangesetPB$json = const {
  '1': 'TypeOptionChangesetPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'type_option_data', '3': 3, '4': 1, '5': 12, '10': 'typeOptionData'},
  ],
};

/// Descriptor for `TypeOptionChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typeOptionChangesetPBDescriptor = $convert.base64Decode('ChVUeXBlT3B0aW9uQ2hhbmdlc2V0UEISFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEhkKCGZpZWxkX2lkGAIgASgJUgdmaWVsZElkEigKEHR5cGVfb3B0aW9uX2RhdGEYAyABKAxSDnR5cGVPcHRpb25EYXRh');
@$core.Deprecated('Use getFieldPayloadPBDescriptor instead')
const GetFieldPayloadPB$json = const {
  '1': 'GetFieldPayloadPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_ids', '3': 2, '4': 1, '5': 11, '6': '.RepeatedFieldIdPB', '9': 0, '10': 'fieldIds'},
  ],
  '8': const [
    const {'1': 'one_of_field_ids'},
  ],
};

/// Descriptor for `GetFieldPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFieldPayloadPBDescriptor = $convert.base64Decode('ChFHZXRGaWVsZFBheWxvYWRQQhIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSMQoJZmllbGRfaWRzGAIgASgLMhIuUmVwZWF0ZWRGaWVsZElkUEJIAFIIZmllbGRJZHNCEgoQb25lX29mX2ZpZWxkX2lkcw==');
@$core.Deprecated('Use fieldChangesetPBDescriptor instead')
const FieldChangesetPB$json = const {
  '1': 'FieldChangesetPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'desc'},
    const {'1': 'field_type', '3': 5, '4': 1, '5': 14, '6': '.FieldType', '9': 2, '10': 'fieldType'},
    const {'1': 'frozen', '3': 6, '4': 1, '5': 8, '9': 3, '10': 'frozen'},
    const {'1': 'visibility', '3': 7, '4': 1, '5': 8, '9': 4, '10': 'visibility'},
    const {'1': 'width', '3': 8, '4': 1, '5': 5, '9': 5, '10': 'width'},
  ],
  '8': const [
    const {'1': 'one_of_name'},
    const {'1': 'one_of_desc'},
    const {'1': 'one_of_field_type'},
    const {'1': 'one_of_frozen'},
    const {'1': 'one_of_visibility'},
    const {'1': 'one_of_width'},
  ],
};

/// Descriptor for `FieldChangesetPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldChangesetPBDescriptor = $convert.base64Decode('ChBGaWVsZENoYW5nZXNldFBCEhkKCGZpZWxkX2lkGAEgASgJUgdmaWVsZElkEhcKB2dyaWRfaWQYAiABKAlSBmdyaWRJZBIUCgRuYW1lGAMgASgJSABSBG5hbWUSFAoEZGVzYxgEIAEoCUgBUgRkZXNjEisKCmZpZWxkX3R5cGUYBSABKA4yCi5GaWVsZFR5cGVIAlIJZmllbGRUeXBlEhgKBmZyb3plbhgGIAEoCEgDUgZmcm96ZW4SIAoKdmlzaWJpbGl0eRgHIAEoCEgEUgp2aXNpYmlsaXR5EhYKBXdpZHRoGAggASgFSAVSBXdpZHRoQg0KC29uZV9vZl9uYW1lQg0KC29uZV9vZl9kZXNjQhMKEW9uZV9vZl9maWVsZF90eXBlQg8KDW9uZV9vZl9mcm96ZW5CEwoRb25lX29mX3Zpc2liaWxpdHlCDgoMb25lX29mX3dpZHRo');
@$core.Deprecated('Use duplicateFieldPayloadPBDescriptor instead')
const DuplicateFieldPayloadPB$json = const {
  '1': 'DuplicateFieldPayloadPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
  ],
};

/// Descriptor for `DuplicateFieldPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List duplicateFieldPayloadPBDescriptor = $convert.base64Decode('ChdEdXBsaWNhdGVGaWVsZFBheWxvYWRQQhIZCghmaWVsZF9pZBgBIAEoCVIHZmllbGRJZBIXCgdncmlkX2lkGAIgASgJUgZncmlkSWQ=');
@$core.Deprecated('Use gridFieldIdentifierPayloadPBDescriptor instead')
const GridFieldIdentifierPayloadPB$json = const {
  '1': 'GridFieldIdentifierPayloadPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
  ],
};

/// Descriptor for `GridFieldIdentifierPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gridFieldIdentifierPayloadPBDescriptor = $convert.base64Decode('ChxHcmlkRmllbGRJZGVudGlmaWVyUGF5bG9hZFBCEhkKCGZpZWxkX2lkGAEgASgJUgdmaWVsZElkEhcKB2dyaWRfaWQYAiABKAlSBmdyaWRJZA==');
@$core.Deprecated('Use deleteFieldPayloadPBDescriptor instead')
const DeleteFieldPayloadPB$json = const {
  '1': 'DeleteFieldPayloadPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'grid_id', '3': 2, '4': 1, '5': 9, '10': 'gridId'},
  ],
};

/// Descriptor for `DeleteFieldPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteFieldPayloadPBDescriptor = $convert.base64Decode('ChREZWxldGVGaWVsZFBheWxvYWRQQhIZCghmaWVsZF9pZBgBIAEoCVIHZmllbGRJZBIXCgdncmlkX2lkGAIgASgJUgZncmlkSWQ=');
