///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use folderEventDescriptor instead')
const FolderEvent$json = const {
  '1': 'FolderEvent',
  '2': const [
    const {'1': 'CreateWorkspace', '2': 0},
    const {'1': 'ReadCurrentWorkspace', '2': 1},
    const {'1': 'ReadWorkspaces', '2': 2},
    const {'1': 'DeleteWorkspace', '2': 3},
    const {'1': 'OpenWorkspace', '2': 4},
    const {'1': 'ReadWorkspaceApps', '2': 5},
    const {'1': 'CreateApp', '2': 101},
    const {'1': 'DeleteApp', '2': 102},
    const {'1': 'ReadApp', '2': 103},
    const {'1': 'UpdateApp', '2': 104},
    const {'1': 'CreateView', '2': 201},
    const {'1': 'ReadView', '2': 202},
    const {'1': 'UpdateView', '2': 203},
    const {'1': 'DeleteView', '2': 204},
    const {'1': 'DuplicateView', '2': 205},
    const {'1': 'CloseView', '2': 206},
    const {'1': 'ReadViewInfo', '2': 207},
    const {'1': 'CopyLink', '2': 220},
    const {'1': 'SetLatestView', '2': 221},
    const {'1': 'MoveFolderItem', '2': 230},
    const {'1': 'ReadTrash', '2': 300},
    const {'1': 'PutbackTrash', '2': 301},
    const {'1': 'DeleteTrash', '2': 302},
    const {'1': 'RestoreAllTrash', '2': 303},
    const {'1': 'DeleteAllTrash', '2': 304},
  ],
};

/// Descriptor for `FolderEvent`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List folderEventDescriptor = $convert.base64Decode('CgtGb2xkZXJFdmVudBITCg9DcmVhdGVXb3Jrc3BhY2UQABIYChRSZWFkQ3VycmVudFdvcmtzcGFjZRABEhIKDlJlYWRXb3Jrc3BhY2VzEAISEwoPRGVsZXRlV29ya3NwYWNlEAMSEQoNT3BlbldvcmtzcGFjZRAEEhUKEVJlYWRXb3Jrc3BhY2VBcHBzEAUSDQoJQ3JlYXRlQXBwEGUSDQoJRGVsZXRlQXBwEGYSCwoHUmVhZEFwcBBnEg0KCVVwZGF0ZUFwcBBoEg8KCkNyZWF0ZVZpZXcQyQESDQoIUmVhZFZpZXcQygESDwoKVXBkYXRlVmlldxDLARIPCgpEZWxldGVWaWV3EMwBEhIKDUR1cGxpY2F0ZVZpZXcQzQESDgoJQ2xvc2VWaWV3EM4BEhEKDFJlYWRWaWV3SW5mbxDPARINCghDb3B5TGluaxDcARISCg1TZXRMYXRlc3RWaWV3EN0BEhMKDk1vdmVGb2xkZXJJdGVtEOYBEg4KCVJlYWRUcmFzaBCsAhIRCgxQdXRiYWNrVHJhc2gQrQISEAoLRGVsZXRlVHJhc2gQrgISFAoPUmVzdG9yZUFsbFRyYXNoEK8CEhMKDkRlbGV0ZUFsbFRyYXNoELAC');
