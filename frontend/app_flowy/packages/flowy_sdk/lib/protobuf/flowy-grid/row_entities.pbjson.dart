///
//  Generated code. Do not modify.
//  source: row_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use rowPBDescriptor instead')
const RowPB$json = const {
  '1': 'RowPB',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'height', '3': 3, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `RowPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowPBDescriptor = $convert.base64Decode('CgVSb3dQQhIZCghibG9ja19pZBgBIAEoCVIHYmxvY2tJZBIOCgJpZBgCIAEoCVICaWQSFgoGaGVpZ2h0GAMgASgFUgZoZWlnaHQ=');
@$core.Deprecated('Use optionalRowPBDescriptor instead')
const OptionalRowPB$json = const {
  '1': 'OptionalRowPB',
  '2': const [
    const {'1': 'row', '3': 1, '4': 1, '5': 11, '6': '.RowPB', '9': 0, '10': 'row'},
  ],
  '8': const [
    const {'1': 'one_of_row'},
  ],
};

/// Descriptor for `OptionalRowPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List optionalRowPBDescriptor = $convert.base64Decode('Cg1PcHRpb25hbFJvd1BCEhoKA3JvdxgBIAEoCzIGLlJvd1BCSABSA3Jvd0IMCgpvbmVfb2Zfcm93');
@$core.Deprecated('Use repeatedRowPBDescriptor instead')
const RepeatedRowPB$json = const {
  '1': 'RepeatedRowPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.RowPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedRowPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedRowPBDescriptor = $convert.base64Decode('Cg1SZXBlYXRlZFJvd1BCEhwKBWl0ZW1zGAEgAygLMgYuUm93UEJSBWl0ZW1z');
@$core.Deprecated('Use insertedRowPBDescriptor instead')
const InsertedRowPB$json = const {
  '1': 'InsertedRowPB',
  '2': const [
    const {'1': 'row', '3': 1, '4': 1, '5': 11, '6': '.RowPB', '10': 'row'},
    const {'1': 'index', '3': 2, '4': 1, '5': 5, '9': 0, '10': 'index'},
    const {'1': 'is_new', '3': 3, '4': 1, '5': 8, '10': 'isNew'},
  ],
  '8': const [
    const {'1': 'one_of_index'},
  ],
};

/// Descriptor for `InsertedRowPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List insertedRowPBDescriptor = $convert.base64Decode('Cg1JbnNlcnRlZFJvd1BCEhgKA3JvdxgBIAEoCzIGLlJvd1BCUgNyb3cSFgoFaW5kZXgYAiABKAVIAFIFaW5kZXgSFQoGaXNfbmV3GAMgASgIUgVpc05ld0IOCgxvbmVfb2ZfaW5kZXg=');
@$core.Deprecated('Use updatedRowPBDescriptor instead')
const UpdatedRowPB$json = const {
  '1': 'UpdatedRowPB',
  '2': const [
    const {'1': 'row', '3': 1, '4': 1, '5': 11, '6': '.RowPB', '10': 'row'},
    const {'1': 'field_ids', '3': 2, '4': 3, '5': 9, '10': 'fieldIds'},
  ],
};

/// Descriptor for `UpdatedRowPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatedRowPBDescriptor = $convert.base64Decode('CgxVcGRhdGVkUm93UEISGAoDcm93GAEgASgLMgYuUm93UEJSA3JvdxIbCglmaWVsZF9pZHMYAiADKAlSCGZpZWxkSWRz');
@$core.Deprecated('Use rowIdPBDescriptor instead')
const RowIdPB$json = const {
  '1': 'RowIdPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'row_id', '3': 2, '4': 1, '5': 9, '10': 'rowId'},
  ],
};

/// Descriptor for `RowIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowIdPBDescriptor = $convert.base64Decode('CgdSb3dJZFBCEhcKB2dyaWRfaWQYASABKAlSBmdyaWRJZBIVCgZyb3dfaWQYAiABKAlSBXJvd0lk');
@$core.Deprecated('Use blockRowIdPBDescriptor instead')
const BlockRowIdPB$json = const {
  '1': 'BlockRowIdPB',
  '2': const [
    const {'1': 'block_id', '3': 1, '4': 1, '5': 9, '10': 'blockId'},
    const {'1': 'row_id', '3': 2, '4': 1, '5': 9, '10': 'rowId'},
  ],
};

/// Descriptor for `BlockRowIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockRowIdPBDescriptor = $convert.base64Decode('CgxCbG9ja1Jvd0lkUEISGQoIYmxvY2tfaWQYASABKAlSB2Jsb2NrSWQSFQoGcm93X2lkGAIgASgJUgVyb3dJZA==');
@$core.Deprecated('Use createTableRowPayloadPBDescriptor instead')
const CreateTableRowPayloadPB$json = const {
  '1': 'CreateTableRowPayloadPB',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'start_row_id', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'startRowId'},
  ],
  '8': const [
    const {'1': 'one_of_start_row_id'},
  ],
};

/// Descriptor for `CreateTableRowPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createTableRowPayloadPBDescriptor = $convert.base64Decode('ChdDcmVhdGVUYWJsZVJvd1BheWxvYWRQQhIXCgdncmlkX2lkGAEgASgJUgZncmlkSWQSIgoMc3RhcnRfcm93X2lkGAIgASgJSABSCnN0YXJ0Um93SWRCFQoTb25lX29mX3N0YXJ0X3Jvd19pZA==');
