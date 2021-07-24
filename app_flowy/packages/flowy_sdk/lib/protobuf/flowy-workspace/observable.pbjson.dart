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
    const {'1': 'WorkspaceUpdateDesc', '2': 10},
    const {'1': 'WorkspaceAddApp', '2': 11},
    const {'1': 'AppUpdateDesc', '2': 20},
    const {'1': 'AppAddView', '2': 21},
    const {'1': 'ViewUpdateDesc', '2': 30},
  ],
};

/// Descriptor for `WorkspaceObservable`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List workspaceObservableDescriptor = $convert.base64Decode('ChNXb3Jrc3BhY2VPYnNlcnZhYmxlEgsKB1Vua25vd24QABIXChNXb3Jrc3BhY2VVcGRhdGVEZXNjEAoSEwoPV29ya3NwYWNlQWRkQXBwEAsSEQoNQXBwVXBkYXRlRGVzYxAUEg4KCkFwcEFkZFZpZXcQFRISCg5WaWV3VXBkYXRlRGVzYxAe');
