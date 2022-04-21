///
//  Generated code. Do not modify.
//  source: cell_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createSelectOptionPayloadDescriptor instead')
const CreateSelectOptionPayload$json = const {
  '1': 'CreateSelectOptionPayload',
  '2': const [
    const {'1': 'field_identifier', '3': 1, '4': 1, '5': 11, '6': '.FieldIdentifierPayload', '10': 'fieldIdentifier'},
    const {'1': 'option_name', '3': 2, '4': 1, '5': 9, '10': 'optionName'},
  ],
};

/// Descriptor for `CreateSelectOptionPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSelectOptionPayloadDescriptor = $convert.base64Decode('ChlDcmVhdGVTZWxlY3RPcHRpb25QYXlsb2FkEkIKEGZpZWxkX2lkZW50aWZpZXIYASABKAsyFy5GaWVsZElkZW50aWZpZXJQYXlsb2FkUg9maWVsZElkZW50aWZpZXISHwoLb3B0aW9uX25hbWUYAiABKAlSCm9wdGlvbk5hbWU=');
@$core.Deprecated('Use cellIdentifierPayloadDescriptor instead')
const CellIdentifierPayload$json = const {
  '1': 'CellIdentifierPayload',
  '2': const [
    const {'1': 'grid_id', '3': 1, '4': 1, '5': 9, '10': 'gridId'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'row_id', '3': 3, '4': 1, '5': 9, '10': 'rowId'},
  ],
};

/// Descriptor for `CellIdentifierPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellIdentifierPayloadDescriptor = $convert.base64Decode('ChVDZWxsSWRlbnRpZmllclBheWxvYWQSFwoHZ3JpZF9pZBgBIAEoCVIGZ3JpZElkEhkKCGZpZWxkX2lkGAIgASgJUgdmaWVsZElkEhUKBnJvd19pZBgDIAEoCVIFcm93SWQ=');
