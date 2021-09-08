///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userObservableDescriptor instead')
const UserObservable$json = const {
  '1': 'UserObservable',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'UserAuthChanged', '2': 1},
    const {'1': 'UserProfileUpdated', '2': 2},
    const {'1': 'UserUnauthorized', '2': 3},
  ],
};

/// Descriptor for `UserObservable`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List userObservableDescriptor = $convert.base64Decode('Cg5Vc2VyT2JzZXJ2YWJsZRILCgdVbmtub3duEAASEwoPVXNlckF1dGhDaGFuZ2VkEAESFgoSVXNlclByb2ZpbGVVcGRhdGVkEAISFAoQVXNlclVuYXV0aG9yaXplZBAD');
