///
//  Generated code. Do not modify.
//  source: util.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use filterPBDescriptor instead')
const FilterPB$json = const {
  '1': 'FilterPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'field_id', '3': 2, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 3, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'data', '3': 4, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `FilterPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterPBDescriptor = $convert.base64Decode('CghGaWx0ZXJQQhIOCgJpZBgBIAEoCVICaWQSGQoIZmllbGRfaWQYAiABKAlSB2ZpZWxkSWQSKQoKZmllbGRfdHlwZRgDIAEoDjIKLkZpZWxkVHlwZVIJZmllbGRUeXBlEhIKBGRhdGEYBCABKAxSBGRhdGE=');
@$core.Deprecated('Use repeatedFilterPBDescriptor instead')
const RepeatedFilterPB$json = const {
  '1': 'RepeatedFilterPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.FilterPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedFilterPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedFilterPBDescriptor = $convert.base64Decode('ChBSZXBlYXRlZEZpbHRlclBCEh8KBWl0ZW1zGAEgAygLMgkuRmlsdGVyUEJSBWl0ZW1z');
@$core.Deprecated('Use deleteFilterPayloadPBDescriptor instead')
const DeleteFilterPayloadPB$json = const {
  '1': 'DeleteFilterPayloadPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 2, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'filter_id', '3': 3, '4': 1, '5': 9, '10': 'filterId'},
    const {'1': 'view_id', '3': 4, '4': 1, '5': 9, '10': 'viewId'},
  ],
};

/// Descriptor for `DeleteFilterPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteFilterPayloadPBDescriptor = $convert.base64Decode('ChVEZWxldGVGaWx0ZXJQYXlsb2FkUEISGQoIZmllbGRfaWQYASABKAlSB2ZpZWxkSWQSKQoKZmllbGRfdHlwZRgCIAEoDjIKLkZpZWxkVHlwZVIJZmllbGRUeXBlEhsKCWZpbHRlcl9pZBgDIAEoCVIIZmlsdGVySWQSFwoHdmlld19pZBgEIAEoCVIGdmlld0lk');
@$core.Deprecated('Use alterFilterPayloadPBDescriptor instead')
const AlterFilterPayloadPB$json = const {
  '1': 'AlterFilterPayloadPB',
  '2': const [
    const {'1': 'field_id', '3': 1, '4': 1, '5': 9, '10': 'fieldId'},
    const {'1': 'field_type', '3': 2, '4': 1, '5': 14, '6': '.FieldType', '10': 'fieldType'},
    const {'1': 'filter_id', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'filterId'},
    const {'1': 'data', '3': 4, '4': 1, '5': 12, '10': 'data'},
    const {'1': 'view_id', '3': 5, '4': 1, '5': 9, '10': 'viewId'},
  ],
  '8': const [
    const {'1': 'one_of_filter_id'},
  ],
};

/// Descriptor for `AlterFilterPayloadPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List alterFilterPayloadPBDescriptor = $convert.base64Decode('ChRBbHRlckZpbHRlclBheWxvYWRQQhIZCghmaWVsZF9pZBgBIAEoCVIHZmllbGRJZBIpCgpmaWVsZF90eXBlGAIgASgOMgouRmllbGRUeXBlUglmaWVsZFR5cGUSHQoJZmlsdGVyX2lkGAMgASgJSABSCGZpbHRlcklkEhIKBGRhdGEYBCABKAxSBGRhdGESFwoHdmlld19pZBgFIAEoCVIGdmlld0lkQhIKEG9uZV9vZl9maWx0ZXJfaWQ=');
