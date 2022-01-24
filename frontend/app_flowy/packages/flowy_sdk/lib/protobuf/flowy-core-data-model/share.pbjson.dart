///
//  Generated code. Do not modify.
//  source: share.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

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
@$core.Deprecated('Use exportRequestDescriptor instead')
const ExportRequest$json = const {
  '1': 'ExportRequest',
  '2': const [
    const {'1': 'doc_id', '3': 1, '4': 1, '5': 9, '10': 'docId'},
    const {'1': 'export_type', '3': 2, '4': 1, '5': 14, '6': '.ExportType', '10': 'exportType'},
  ],
};

/// Descriptor for `ExportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportRequestDescriptor = $convert.base64Decode('Cg1FeHBvcnRSZXF1ZXN0EhUKBmRvY19pZBgBIAEoCVIFZG9jSWQSLAoLZXhwb3J0X3R5cGUYAiABKA4yCy5FeHBvcnRUeXBlUgpleHBvcnRUeXBl');
@$core.Deprecated('Use exportDataDescriptor instead')
const ExportData$json = const {
  '1': 'ExportData',
  '2': const [
    const {'1': 'data', '3': 1, '4': 1, '5': 9, '10': 'data'},
    const {'1': 'export_type', '3': 2, '4': 1, '5': 14, '6': '.ExportType', '10': 'exportType'},
  ],
};

/// Descriptor for `ExportData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportDataDescriptor = $convert.base64Decode('CgpFeHBvcnREYXRhEhIKBGRhdGEYASABKAlSBGRhdGESLAoLZXhwb3J0X3R5cGUYAiABKA4yCy5FeHBvcnRUeXBlUgpleHBvcnRUeXBl');
