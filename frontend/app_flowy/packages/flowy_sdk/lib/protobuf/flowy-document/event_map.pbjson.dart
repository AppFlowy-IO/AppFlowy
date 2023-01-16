///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use documentEventDescriptor instead')
const DocumentEvent$json = const {
  '1': 'DocumentEvent',
  '2': const [
    const {'1': 'GetDocument', '2': 0},
    const {'1': 'ApplyEdit', '2': 1},
    const {'1': 'ExportDocument', '2': 2},
  ],
};

/// Descriptor for `DocumentEvent`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List documentEventDescriptor = $convert.base64Decode('Cg1Eb2N1bWVudEV2ZW50Eg8KC0dldERvY3VtZW50EAASDQoJQXBwbHlFZGl0EAESEgoORXhwb3J0RG9jdW1lbnQQAg==');
