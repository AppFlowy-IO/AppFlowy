///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userNotificationDescriptor instead')
const UserNotification$json = const {
  '1': 'UserNotification',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'UserAuthChanged', '2': 1},
    const {'1': 'UserProfileUpdated', '2': 2},
    const {'1': 'UserUnauthorized', '2': 3},
    const {'1': 'UserWsConnectStateChanged', '2': 4},
  ],
};

/// Descriptor for `UserNotification`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List userNotificationDescriptor = $convert.base64Decode('ChBVc2VyTm90aWZpY2F0aW9uEgsKB1Vua25vd24QABITCg9Vc2VyQXV0aENoYW5nZWQQARIWChJVc2VyUHJvZmlsZVVwZGF0ZWQQAhIUChBVc2VyVW5hdXRob3JpemVkEAMSHQoZVXNlcldzQ29ubmVjdFN0YXRlQ2hhbmdlZBAE');
