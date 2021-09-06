///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use workspaceObservableDescriptor instead')
const WorkspaceObservable$json = const {
  '1': 'WorkspaceObservable',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'UserCreateWorkspace', '2': 10},
    const {'1': 'UserDeleteWorkspace', '2': 11},
    const {'1': 'WorkspaceUpdated', '2': 12},
    const {'1': 'WorkspaceCreateApp', '2': 13},
    const {'1': 'WorkspaceDeleteApp', '2': 14},
    const {'1': 'WorkspaceListUpdated', '2': 15},
    const {'1': 'AppUpdated', '2': 21},
    const {'1': 'AppCreateView', '2': 23},
    const {'1': 'AppDeleteView', '2': 24},
    const {'1': 'ViewUpdated', '2': 31},
  ],
};

/// Descriptor for `WorkspaceObservable`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceObservableDescriptor = $convert.base64Decode('ChNXb3Jrc3BhY2VPYnNlcnZhYmxlEgsKB1Vua25vd24QABIXChNVc2VyQ3JlYXRlV29ya3NwYWNlEAoSFwoTVXNlckRlbGV0ZVdvcmtzcGFjZRALEhQKEFdvcmtzcGFjZVVwZGF0ZWQQDBIWChJXb3Jrc3BhY2VDcmVhdGVBcHAQDRIWChJXb3Jrc3BhY2VEZWxldGVBcHAQDhIYChRXb3Jrc3BhY2VMaXN0VXBkYXRlZBAPEg4KCkFwcFVwZGF0ZWQQFRIRCg1BcHBDcmVhdGVWaWV3EBcSEQoNQXBwRGVsZXRlVmlldxAYEg8KC1ZpZXdVcGRhdGVkEB8=');
