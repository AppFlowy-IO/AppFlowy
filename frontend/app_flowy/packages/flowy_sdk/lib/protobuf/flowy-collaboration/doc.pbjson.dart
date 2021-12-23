///
//  Generated code. Do not modify.
//  source: doc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use createDocParamsDescriptor instead')
const CreateDocParams$json = const {
  '1': 'CreateDocParams',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'revisions', '3': 2, '4': 1, '5': 11, '6': '.RepeatedRevision', '10': 'revisions'},
  ],
};

/// Descriptor for `CreateDocParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createDocParamsDescriptor = $convert.base64Decode('Cg9DcmVhdGVEb2NQYXJhbXMSDgoCaWQYASABKAlSAmlkEi8KCXJldmlzaW9ucxgCIAEoCzIRLlJlcGVhdGVkUmV2aXNpb25SCXJldmlzaW9ucw==');
@$core.Deprecated('Use documentInfoDescriptor instead')
const DocumentInfo$json = const {
  '1': 'DocumentInfo',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    const {'1': 'rev_id', '3': 3, '4': 1, '5': 3, '10': 'revId'},
    const {'1': 'base_rev_id', '3': 4, '4': 1, '5': 3, '10': 'baseRevId'},
  ],
};

/// Descriptor for `DocumentInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentInfoDescriptor = $convert.base64Decode('CgxEb2N1bWVudEluZm8SDgoCaWQYASABKAlSAmlkEhIKBHRleHQYAiABKAlSBHRleHQSFQoGcmV2X2lkGAMgASgDUgVyZXZJZBIeCgtiYXNlX3Jldl9pZBgEIAEoA1IJYmFzZVJldklk');
@$core.Deprecated('Use resetDocumentParamsDescriptor instead')
const ResetDocumentParams$json = const {
  '1': 'ResetDocumentParams',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'revisions', '3': 2, '4': 1, '5': 11, '6': '.RepeatedRevision', '10': 'revisions'},
  ],
};

/// Descriptor for `ResetDocumentParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetDocumentParamsDescriptor = $convert.base64Decode('ChNSZXNldERvY3VtZW50UGFyYW1zEhUKBmRvY19pZBgBIAEoCVIFZG9jSWQSLwoJcmV2aXNpb25zGAIgASgLMhEuUmVwZWF0ZWRSZXZpc2lvblIJcmV2aXNpb25z');
@$core.Deprecated('Use documentDeltaDescriptor instead')
const DocumentDelta$json = const {
  '1': 'DocumentDelta',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `DocumentDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentDeltaDescriptor = $convert.base64Decode('Cg1Eb2N1bWVudERlbHRhEhUKBmRvY19pZBgBIAEoCVIFZG9jSWQSEgoEdGV4dBgCIAEoCVIEdGV4dA==');
@$core.Deprecated('Use newDocUserDescriptor instead')
const NewDocUser$json = const {
  '1': 'NewDocUser',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'rev_id', '3': 2, '4': 1, '5': 3, '10': 'revId'},
    const {'1': 'doc_id', '3': 3, '4': 1, '5': 9, '10': 'docId'},
  ],
};

/// Descriptor for `NewDocUser`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newDocUserDescriptor = $convert.base64Decode('CgpOZXdEb2NVc2VyEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIVCgZyZXZfaWQYAiABKANSBXJldklkEhUKBmRvY19pZBgDIAEoCVIFZG9jSWQ=');
@$core.Deprecated('Use docIdentifierDescriptor instead')
const DocIdentifier$json = const {
  '1': 'DocIdentifier',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
  ],
};

/// Descriptor for `DocIdentifier`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docIdentifierDescriptor = $convert.base64Decode('Cg1Eb2NJZGVudGlmaWVyEhUKBmRvY19pZBgBIAEoCVIFZG9jSWQ=');
