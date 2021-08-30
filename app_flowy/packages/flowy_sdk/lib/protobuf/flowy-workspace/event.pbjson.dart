///
//  Generated code. Do not modify.
//  source: event.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use workspaceEventDescriptor instead')
const WorkspaceEvent$json = const {
  '1': 'WorkspaceEvent',
  '2': const [
    const {'1': 'CreateWorkspace', '2': 0},
    const {'1': 'ReadCurWorkspace', '2': 1},
    const {'1': 'ReadWorkspaces', '2': 2},
    const {'1': 'DeleteWorkspace', '2': 3},
    const {'1': 'OpenWorkspace', '2': 4},
    const {'1': 'CreateApp', '2': 101},
    const {'1': 'DeleteApp', '2': 102},
    const {'1': 'ReadApp', '2': 103},
    const {'1': 'UpdateApp', '2': 104},
    const {'1': 'CreateView', '2': 201},
    const {'1': 'ReadView', '2': 202},
    const {'1': 'UpdateView', '2': 203},
    const {'1': 'DeleteView', '2': 204},
  ],
};

/// Descriptor for `WorkspaceEvent`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceEventDescriptor = $convert.base64Decode('Cg5Xb3Jrc3BhY2VFdmVudBITCg9DcmVhdGVXb3Jrc3BhY2UQABIUChBSZWFkQ3VyV29ya3NwYWNlEAESEgoOUmVhZFdvcmtzcGFjZXMQAhITCg9EZWxldGVXb3Jrc3BhY2UQAxIRCg1PcGVuV29ya3NwYWNlEAQSDQoJQ3JlYXRlQXBwEGUSDQoJRGVsZXRlQXBwEGYSCwoHUmVhZEFwcBBnEg0KCVVwZGF0ZUFwcBBoEg8KCkNyZWF0ZVZpZXcQyQESDQoIUmVhZFZpZXcQygESDwoKVXBkYXRlVmlldxDLARIPCgpEZWxldGVWaWV3EMwB');
