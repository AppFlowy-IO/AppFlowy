///
//  Generated code. Do not modify.
//  source: event_map.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use gridEventDescriptor instead')
const GridEvent$json = const {
  '1': 'GridEvent',
  '2': const [
    const {'1': 'GetGrid', '2': 0},
    const {'1': 'GetGridSetting', '2': 2},
    const {'1': 'UpdateGridSetting', '2': 3},
    const {'1': 'GetAllFilters', '2': 4},
    const {'1': 'GetFields', '2': 10},
    const {'1': 'UpdateField', '2': 11},
    const {'1': 'UpdateFieldTypeOption', '2': 12},
    const {'1': 'DeleteField', '2': 14},
    const {'1': 'SwitchToField', '2': 20},
    const {'1': 'DuplicateField', '2': 21},
    const {'1': 'MoveField', '2': 22},
    const {'1': 'GetFieldTypeOption', '2': 23},
    const {'1': 'CreateFieldTypeOption', '2': 24},
    const {'1': 'NewSelectOption', '2': 30},
    const {'1': 'GetSelectOptionCellData', '2': 31},
    const {'1': 'UpdateSelectOption', '2': 32},
    const {'1': 'CreateTableRow', '2': 50},
    const {'1': 'GetRow', '2': 51},
    const {'1': 'DeleteRow', '2': 52},
    const {'1': 'DuplicateRow', '2': 53},
    const {'1': 'MoveRow', '2': 54},
    const {'1': 'GetCell', '2': 70},
    const {'1': 'UpdateCell', '2': 71},
    const {'1': 'UpdateSelectOptionCell', '2': 72},
    const {'1': 'UpdateDateCell', '2': 80},
    const {'1': 'GetGroup', '2': 100},
    const {'1': 'CreateBoardCard', '2': 110},
    const {'1': 'MoveGroup', '2': 111},
    const {'1': 'MoveGroupRow', '2': 112},
    const {'1': 'GroupByField', '2': 113},
  ],
};

/// Descriptor for `GridEvent`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gridEventDescriptor = $convert.base64Decode('CglHcmlkRXZlbnQSCwoHR2V0R3JpZBAAEhIKDkdldEdyaWRTZXR0aW5nEAISFQoRVXBkYXRlR3JpZFNldHRpbmcQAxIRCg1HZXRBbGxGaWx0ZXJzEAQSDQoJR2V0RmllbGRzEAoSDwoLVXBkYXRlRmllbGQQCxIZChVVcGRhdGVGaWVsZFR5cGVPcHRpb24QDBIPCgtEZWxldGVGaWVsZBAOEhEKDVN3aXRjaFRvRmllbGQQFBISCg5EdXBsaWNhdGVGaWVsZBAVEg0KCU1vdmVGaWVsZBAWEhYKEkdldEZpZWxkVHlwZU9wdGlvbhAXEhkKFUNyZWF0ZUZpZWxkVHlwZU9wdGlvbhAYEhMKD05ld1NlbGVjdE9wdGlvbhAeEhsKF0dldFNlbGVjdE9wdGlvbkNlbGxEYXRhEB8SFgoSVXBkYXRlU2VsZWN0T3B0aW9uECASEgoOQ3JlYXRlVGFibGVSb3cQMhIKCgZHZXRSb3cQMxINCglEZWxldGVSb3cQNBIQCgxEdXBsaWNhdGVSb3cQNRILCgdNb3ZlUm93EDYSCwoHR2V0Q2VsbBBGEg4KClVwZGF0ZUNlbGwQRxIaChZVcGRhdGVTZWxlY3RPcHRpb25DZWxsEEgSEgoOVXBkYXRlRGF0ZUNlbGwQUBIMCghHZXRHcm91cBBkEhMKD0NyZWF0ZUJvYXJkQ2FyZBBuEg0KCU1vdmVHcm91cBBvEhAKDE1vdmVHcm91cFJvdxBwEhAKDEdyb3VwQnlGaWVsZBBx');
