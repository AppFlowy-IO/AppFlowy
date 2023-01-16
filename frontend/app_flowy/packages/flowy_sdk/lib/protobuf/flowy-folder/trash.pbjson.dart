///
//  Generated code. Do not modify.
//  source: trash.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use trashTypeDescriptor instead')
const TrashType$json = const {
  '1': 'TrashType',
  '2': const [
    const {'1': 'TrashUnknown', '2': 0},
    const {'1': 'TrashView', '2': 1},
    const {'1': 'TrashApp', '2': 2},
  ],
};

/// Descriptor for `TrashType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trashTypeDescriptor = $convert.base64Decode('CglUcmFzaFR5cGUSEAoMVHJhc2hVbmtub3duEAASDQoJVHJhc2hWaWV3EAESDAoIVHJhc2hBcHAQAg==');
@$core.Deprecated('Use trashPBDescriptor instead')
const TrashPB$json = const {
  '1': 'TrashPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'modified_time', '3': 3, '4': 1, '5': 3, '10': 'modifiedTime'},
    const {'1': 'create_time', '3': 4, '4': 1, '5': 3, '10': 'createTime'},
    const {'1': 'ty', '3': 5, '4': 1, '5': 14, '6': '.TrashType', '10': 'ty'},
  ],
};

/// Descriptor for `TrashPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trashPBDescriptor = $convert.base64Decode('CgdUcmFzaFBCEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEiMKDW1vZGlmaWVkX3RpbWUYAyABKANSDG1vZGlmaWVkVGltZRIfCgtjcmVhdGVfdGltZRgEIAEoA1IKY3JlYXRlVGltZRIaCgJ0eRgFIAEoDjIKLlRyYXNoVHlwZVICdHk=');
@$core.Deprecated('Use repeatedTrashPBDescriptor instead')
const RepeatedTrashPB$json = const {
  '1': 'RepeatedTrashPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.TrashPB', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedTrashPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedTrashPBDescriptor = $convert.base64Decode('Cg9SZXBlYXRlZFRyYXNoUEISHgoFaXRlbXMYASADKAsyCC5UcmFzaFBCUgVpdGVtcw==');
@$core.Deprecated('Use repeatedTrashIdPBDescriptor instead')
const RepeatedTrashIdPB$json = const {
  '1': 'RepeatedTrashIdPB',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.TrashIdPB', '10': 'items'},
    const {'1': 'delete_all', '3': 2, '4': 1, '5': 8, '10': 'deleteAll'},
  ],
};

/// Descriptor for `RepeatedTrashIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedTrashIdPBDescriptor = $convert.base64Decode('ChFSZXBlYXRlZFRyYXNoSWRQQhIgCgVpdGVtcxgBIAMoCzIKLlRyYXNoSWRQQlIFaXRlbXMSHQoKZGVsZXRlX2FsbBgCIAEoCFIJZGVsZXRlQWxs');
@$core.Deprecated('Use trashIdPBDescriptor instead')
const TrashIdPB$json = const {
  '1': 'TrashIdPB',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'ty', '3': 2, '4': 1, '5': 14, '6': '.TrashType', '10': 'ty'},
  ],
};

/// Descriptor for `TrashIdPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trashIdPBDescriptor = $convert.base64Decode('CglUcmFzaElkUEISDgoCaWQYASABKAlSAmlkEhoKAnR5GAIgASgOMgouVHJhc2hUeXBlUgJ0eQ==');
