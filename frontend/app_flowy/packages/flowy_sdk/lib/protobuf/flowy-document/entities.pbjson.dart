///
//  Generated code. Do not modify.
//  source: entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use exportTypeDescriptor instead')
const ExportType$json = const {
  '1': 'ExportType',
  '2': const [
    const {'1': 'Text', '2': 0},
    const {'1': 'Markdown', '2': 1},
    const {'1': 'Link', '2': 2},
  ],
};

/// Descriptor for `ExportType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List exportTypeDescriptor = $convert.base64Decode('CgpFeHBvcnRUeXBlEggKBFRleHQQABIMCghNYXJrZG93bhABEggKBExpbmsQAg==');
@$core.Deprecated('Use documentVersionPBDescriptor instead')
const DocumentVersionPB$json = const {
  '1': 'DocumentVersionPB',
  '2': const [
    const {'1': 'V0', '2': 0},
    const {'1': 'V1', '2': 1},
  ],
};

/// Descriptor for `DocumentVersionPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List documentVersionPBDescriptor = $convert.base64Decode('ChFEb2N1bWVudFZlcnNpb25QQhIGCgJWMBAAEgYKAlYxEAE=');
@$core.Deprecated('Use editPayloadPBDescriptor instead')
const EditPayloadPB$json = const {
  '1': 'EditPayloadPB',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'operations', '3': 2, '4': 1, '5': 9, '10': 'operations'},
  ],
};

/// Descriptor for `EditPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editPayloadPBDescriptor = $convert.base64Decode('Cg1FZGl0UGF5bG9hZFBCEhUKBmRvY19pZBgBIAEoCVIFZG9jSWQSHgoKb3BlcmF0aW9ucxgCIAEoCVIKb3BlcmF0aW9ucw==');
@$core.Deprecated('Use documentSnapshotPBDescriptor instead')
const DocumentSnapshotPB$json = const {
  '1': 'DocumentSnapshotPB',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'snapshot', '3': 2, '4': 1, '5': 9, '10': 'snapshot'},
  ],
};

/// Descriptor for `DocumentSnapshotPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentSnapshotPBDescriptor = $convert.base64Decode('ChJEb2N1bWVudFNuYXBzaG90UEISFQoGZG9jX2lkGAEgASgJUgVkb2NJZBIaCghzbmFwc2hvdBgCIAEoCVIIc25hcHNob3Q=');
@$core.Deprecated('Use exportPayloadPBDescriptor instead')
const ExportPayloadPB$json = const {
  '1': 'ExportPayloadPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'export_type', '3': 2, '4': 1, '5': 14, '6': '.ExportType', '10': 'exportType'},
    const {'1': 'document_version', '3': 3, '4': 1, '5': 14, '6': '.DocumentVersionPB', '10': 'documentVersion'},
  ],
};

/// Descriptor for `ExportPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportPayloadPBDescriptor = $convert.base64Decode('Cg9FeHBvcnRQYXlsb2FkUEISFwoHdmlld19pZBgBIAEoCVIGdmlld0lkEiwKC2V4cG9ydF90eXBlGAIgASgOMgsuRXhwb3J0VHlwZVIKZXhwb3J0VHlwZRI9ChBkb2N1bWVudF92ZXJzaW9uGAMgASgOMhIuRG9jdW1lbnRWZXJzaW9uUEJSD2RvY3VtZW50VmVyc2lvbg==');
@$core.Deprecated('Use openDocumentContextPBDescriptor instead')
const OpenDocumentContextPB$json = const {
  '1': 'OpenDocumentContextPB',
  '2': const [
    const {'1': 'document_id', '3': 1, '4': 1, '5': 9, '10': 'documentId'},
    const {'1': 'document_version', '3': 2, '4': 1, '5': 14, '6': '.DocumentVersionPB', '10': 'documentVersion'},
  ],
};

/// Descriptor for `OpenDocumentContextPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List openDocumentContextPBDescriptor = $convert.base64Decode('ChVPcGVuRG9jdW1lbnRDb250ZXh0UEISHwoLZG9jdW1lbnRfaWQYASABKAlSCmRvY3VtZW50SWQSPQoQZG9jdW1lbnRfdmVyc2lvbhgCIAEoDjISLkRvY3VtZW50VmVyc2lvblBCUg9kb2N1bWVudFZlcnNpb24=');
@$core.Deprecated('Use exportDataPBDescriptor instead')
const ExportDataPB$json = const {
  '1': 'ExportDataPB',
  '2': const [
    const {'1': 'data', '3': 1, '4': 1, '5': 9, '10': 'data'},
    const {'1': 'export_type', '3': 2, '4': 1, '5': 14, '6': '.ExportType', '10': 'exportType'},
  ],
};

/// Descriptor for `ExportDataPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportDataPBDescriptor = $convert.base64Decode('CgxFeHBvcnREYXRhUEISEgoEZGF0YRgBIAEoCVIEZGF0YRIsCgtleHBvcnRfdHlwZRgCIAEoDjILLkV4cG9ydFR5cGVSCmV4cG9ydFR5cGU=');
