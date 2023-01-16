///
//  Generated code. Do not modify.
//  source: dart_notification.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use folderNotificationDescriptor instead')
const FolderNotification$json = const {
  '1': 'FolderNotification',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'UserCreateWorkspace', '2': 10},
    const {'1': 'UserDeleteWorkspace', '2': 11},
    const {'1': 'WorkspaceUpdated', '2': 12},
    const {'1': 'WorkspaceListUpdated', '2': 13},
    const {'1': 'WorkspaceAppsChanged', '2': 14},
    const {'1': 'WorkspaceSetting', '2': 15},
    const {'1': 'AppUpdated', '2': 21},
    const {'1': 'ViewUpdated', '2': 31},
    const {'1': 'ViewDeleted', '2': 32},
    const {'1': 'ViewRestored', '2': 33},
    const {'1': 'ViewMoveToTrash', '2': 34},
    const {'1': 'UserUnauthorized', '2': 100},
    const {'1': 'TrashUpdated', '2': 1000},
  ],
};

/// Descriptor for `FolderNotification`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List folderNotificationDescriptor = $convert.base64Decode('ChJGb2xkZXJOb3RpZmljYXRpb24SCwoHVW5rbm93bhAAEhcKE1VzZXJDcmVhdGVXb3Jrc3BhY2UQChIXChNVc2VyRGVsZXRlV29ya3NwYWNlEAsSFAoQV29ya3NwYWNlVXBkYXRlZBAMEhgKFFdvcmtzcGFjZUxpc3RVcGRhdGVkEA0SGAoUV29ya3NwYWNlQXBwc0NoYW5nZWQQDhIUChBXb3Jrc3BhY2VTZXR0aW5nEA8SDgoKQXBwVXBkYXRlZBAVEg8KC1ZpZXdVcGRhdGVkEB8SDwoLVmlld0RlbGV0ZWQQIBIQCgxWaWV3UmVzdG9yZWQQIRITCg9WaWV3TW92ZVRvVHJhc2gQIhIUChBVc2VyVW5hdXRob3JpemVkEGQSEQoMVHJhc2hVcGRhdGVkEOgH');
