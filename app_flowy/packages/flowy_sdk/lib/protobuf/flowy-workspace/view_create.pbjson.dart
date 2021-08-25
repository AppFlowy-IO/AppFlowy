///
//  Generated code. Do not modify.
//  source: view_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use viewTypeDescriptor instead')
const ViewType$json = const {
  '1': 'ViewType',
  '2': const [
    const {'1': 'Blank', '2': 0},
    const {'1': 'Doc', '2': 1},
  ],
};

/// Descriptor for `ViewType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List viewTypeDescriptor = $convert.base64Decode('CghWaWV3VHlwZRIJCgVCbGFuaxAAEgcKA0RvYxAB');
@$core.Deprecated('Use createViewRequestDescriptor instead')
const CreateViewRequest$json = const {
  '1': 'CreateViewRequest',
  '2': const [
    const {'1': 'belong_to_id', '3': 1, '4': 1, '5': 9, '10': 'belongToId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'thumbnail', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'thumbnail'},
    const {'1': 'view_type', '3': 5, '4': 1, '5': 14, '6': '.ViewType', '10': 'viewType'},
  ],
  '8': const [
    const {'1': 'one_of_thumbnail'},
  ],
};

/// Descriptor for `CreateViewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createViewRequestDescriptor = $convert.base64Decode('ChFDcmVhdGVWaWV3UmVxdWVzdBIgCgxiZWxvbmdfdG9faWQYASABKAlSCmJlbG9uZ1RvSWQSEgoEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEh4KCXRodW1ibmFpbBgEIAEoCUgAUgl0aHVtYm5haWwSJgoJdmlld190eXBlGAUgASgOMgkuVmlld1R5cGVSCHZpZXdUeXBlQhIKEG9uZV9vZl90aHVtYm5haWw=');
@$core.Deprecated('Use createViewParamsDescriptor instead')
const CreateViewParams$json = const {
  '1': 'CreateViewParams',
  '2': const [
    const {'1': 'belong_to_id', '3': 1, '4': 1, '5': 9, '10': 'belongToId'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'thumbnail', '3': 4, '4': 1, '5': 9, '10': 'thumbnail'},
    const {'1': 'view_type', '3': 5, '4': 1, '5': 14, '6': '.ViewType', '10': 'viewType'},
  ],
};

/// Descriptor for `CreateViewParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createViewParamsDescriptor = $convert.base64Decode('ChBDcmVhdGVWaWV3UGFyYW1zEiAKDGJlbG9uZ190b19pZBgBIAEoCVIKYmVsb25nVG9JZBISCgRuYW1lGAIgASgJUgRuYW1lEhIKBGRlc2MYAyABKAlSBGRlc2MSHAoJdGh1bWJuYWlsGAQgASgJUgl0aHVtYm5haWwSJgoJdmlld190eXBlGAUgASgOMgkuVmlld1R5cGVSCHZpZXdUeXBl');
@$core.Deprecated('Use viewDescriptor instead')
const View$json = const {
  '1': 'View',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'belong_to_id', '3': 2, '4': 1, '5': 9, '10': 'belongToId'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'desc', '3': 4, '4': 1, '5': 9, '10': 'desc'},
    const {'1': 'view_type', '3': 5, '4': 1, '5': 14, '6': '.ViewType', '10': 'viewType'},
    const {'1': 'version', '3': 6, '4': 1, '5': 3, '10': 'version'},
    const {'1': 'belongings', '3': 7, '4': 1, '5': 11, '6': '.RepeatedView', '10': 'belongings'},
  ],
};

/// Descriptor for `View`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viewDescriptor = $convert.base64Decode('CgRWaWV3Eg4KAmlkGAEgASgJUgJpZBIgCgxiZWxvbmdfdG9faWQYAiABKAlSCmJlbG9uZ1RvSWQSEgoEbmFtZRgDIAEoCVIEbmFtZRISCgRkZXNjGAQgASgJUgRkZXNjEiYKCXZpZXdfdHlwZRgFIAEoDjIJLlZpZXdUeXBlUgh2aWV3VHlwZRIYCgd2ZXJzaW9uGAYgASgDUgd2ZXJzaW9uEi0KCmJlbG9uZ2luZ3MYByABKAsyDS5SZXBlYXRlZFZpZXdSCmJlbG9uZ2luZ3M=');
@$core.Deprecated('Use repeatedViewDescriptor instead')
const RepeatedView$json = const {
  '1': 'RepeatedView',
  '2': const [
    const {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.View', '10': 'items'},
  ],
};

/// Descriptor for `RepeatedView`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repeatedViewDescriptor = $convert.base64Decode('CgxSZXBlYXRlZFZpZXcSGwoFaXRlbXMYASADKAsyBS5WaWV3UgVpdGVtcw==');
