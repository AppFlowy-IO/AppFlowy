///
//  Generated code. Do not modify.
//  source: model.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use revTypeDescriptor instead')
const RevType$json = const {
  '1': 'RevType',
  '2': const [
    const {'1': 'Local', '2': 0},
    const {'1': 'Remote', '2': 1},
  ],
};

/// Descriptor for `RevType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List revTypeDescriptor = $convert.base64Decode('CgdSZXZUeXBlEgkKBUxvY2FsEAASCgoGUmVtb3RlEAE=');
@$core.Deprecated('Use revStateDescriptor instead')
const RevState$json = const {
  '1': 'RevState',
  '2': const [
    const {'1': 'StateLocal', '2': 0},
    const {'1': 'Ack', '2': 1},
  ],
};

/// Descriptor for `RevState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List revStateDescriptor = $convert.base64Decode('CghSZXZTdGF0ZRIOCgpTdGF0ZUxvY2FsEAASBwoDQWNrEAE=');
@$core.Deprecated('Use revisionDescriptor instead')
const Revision$json = const {
  '1': 'Revision',
  '2': const [
    const {'1': 'base_rev_id', '3': 1, '4': 1, '5': 3, '10': 'baseRevId'},
    const {'1': 'rev_id', '3': 2, '4': 1, '5': 3, '10': 'revId'},
    const {'1': 'delta_data', '3': 3, '4': 1, '5': 12, '10': 'deltaData'},
    const {'1': 'md5', '3': 4, '4': 1, '5': 9, '10': 'md5'},
    const {'1': 'doc_id', '3': 5, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'ty', '3': 6, '4': 1, '5': 14, '6': '.RevType', '10': 'ty'},
    const {'1': 'user_id', '3': 7, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `Revision`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revisionDescriptor = $convert.base64Decode('CghSZXZpc2lvbhIeCgtiYXNlX3Jldl9pZBgBIAEoA1IJYmFzZVJldklkEhUKBnJldl9pZBgCIAEoA1IFcmV2SWQSHQoKZGVsdGFfZGF0YRgDIAEoDFIJZGVsdGFEYXRhEhAKA21kNRgEIAEoCVIDbWQ1EhUKBmRvY19pZBgFIAEoCVIFZG9jSWQSGAoCdHkYBiABKA4yCC5SZXZUeXBlUgJ0eRIXCgd1c2VyX2lkGAcgASgJUgZ1c2VySWQ=');
@$core.Deprecated('Use repeatedRevisionDescriptor instead')
const RepeatedRevision$json = const {
  '1': 'RepeatedRevision',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.Revision', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedRevision`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedRevisionDescriptor = $convert.base64Decode('ChBSZXBlYXRlZFJldmlzaW9uEh8KBWl0ZW1zGAEgAygLMgkuUmV2aXNpb25SBWl0ZW1z');
@$core.Deprecated('Use revIdDescriptor instead')
const RevId$json = const {
  '1': 'RevId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 3, '10': 'value'},
  ],
};

/// Descriptor for `RevId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revIdDescriptor = $convert.base64Decode('CgVSZXZJZBIUCgV2YWx1ZRgBIAEoA1IFdmFsdWU=');
@$core.Deprecated('Use revisionRangeDescriptor instead')
const RevisionRange$json = const {
  '1': 'RevisionRange',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'start', '3': 2, '4': 1, '5': 3, '10': 'start'},
    const {'1': 'end', '3': 3, '4': 1, '5': 3, '10': 'end'},
  ],
};

/// Descriptor for `RevisionRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revisionRangeDescriptor = $convert.base64Decode('Cg1SZXZpc2lvblJhbmdlEhUKBmRvY19pZBgBIAEoCVIFZG9jSWQSFAoFc3RhcnQYAiABKANSBXN0YXJ0EhAKA2VuZBgDIAEoA1IDZW5k');
