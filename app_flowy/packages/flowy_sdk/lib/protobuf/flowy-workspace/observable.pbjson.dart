///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use workspaceNotificationDescriptor instead')
const WorkspaceNotification$json = const {
  '1': 'WorkspaceNotification',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'UserCreateWorkspace', '2': 10},
    const {'1': 'UserDeleteWorkspace', '2': 11},
    const {'1': 'WorkspaceUpdated', '2': 12},
    const {'1': 'WorkspaceCreateApp', '2': 13},
    const {'1': 'WorkspaceDeleteApp', '2': 14},
    const {'1': 'WorkspaceListUpdated', '2': 15},
    const {'1': 'AppUpdated', '2': 21},
    const {'1': 'AppViewsChanged', '2': 24},
    const {'1': 'ViewUpdated', '2': 31},
    const {'1': 'UserUnauthorized', '2': 100},
    const {'1': 'TrashUpdated', '2': 1000},
  ],
};

/// Descriptor for `WorkspaceNotification`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceNotificationDescriptor = $convert.base64Decode('ChVXb3Jrc3BhY2VOb3RpZmljYXRpb24SCwoHVW5rbm93bhAAEhcKE1VzZXJDcmVhdGVXb3Jrc3BhY2UQChIXChNVc2VyRGVsZXRlV29ya3NwYWNlEAsSFAoQV29ya3NwYWNlVXBkYXRlZBAMEhYKEldvcmtzcGFjZUNyZWF0ZUFwcBANEhYKEldvcmtzcGFjZURlbGV0ZUFwcBAOEhgKFFdvcmtzcGFjZUxpc3RVcGRhdGVkEA8SDgoKQXBwVXBkYXRlZBAVEhMKD0FwcFZpZXdzQ2hhbmdlZBAYEg8KC1ZpZXdVcGRhdGVkEB8SFAoQVXNlclVuYXV0aG9yaXplZBBkEhEKDFRyYXNoVXBkYXRlZBDoBw==');
