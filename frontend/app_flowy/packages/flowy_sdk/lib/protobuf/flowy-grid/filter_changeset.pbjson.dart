///
//  Generated code. Do not modify.
//  source: filter_changeset.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use filterChangesetNotificationPBDescriptor instead')
const FilterChangesetNotificationPB$json = const {
  '1': 'FilterChangesetNotificationPB',
  '2': const [
    const {'1': 'view_id', '3': 1, '4': 1, '5': 9, '10': 'viewId'},
    const {'1': 'insert_filters', '3': 2, '4': 3, '5': 11, '6': '.FilterPB', '10': 'insertFilters'},
    const {'1': 'delete_filters', '3': 3, '4': 3, '5': 11, '6': '.FilterPB', '10': 'deleteFilters'},
    const {'1': 'update_filters', '3': 4, '4': 3, '5': 11, '6': '.UpdatedFilter', '10': 'updateFilters'},
  ],
};

/// Descriptor for `FilterChangesetNotificationPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterChangesetNotificationPBDescriptor = $convert.base64Decode('Ch1GaWx0ZXJDaGFuZ2VzZXROb3RpZmljYXRpb25QQhIXCgd2aWV3X2lkGAEgASgJUgZ2aWV3SWQSMAoOaW5zZXJ0X2ZpbHRlcnMYAiADKAsyCS5GaWx0ZXJQQlINaW5zZXJ0RmlsdGVycxIwCg5kZWxldGVfZmlsdGVycxgDIAMoCzIJLkZpbHRlclBCUg1kZWxldGVGaWx0ZXJzEjUKDnVwZGF0ZV9maWx0ZXJzGAQgAygLMg4uVXBkYXRlZEZpbHRlclINdXBkYXRlRmlsdGVycw==');
@$core.Deprecated('Use updatedFilterDescriptor instead')
const UpdatedFilter$json = const {
  '1': 'UpdatedFilter',
  '2': const [
    const {'1': 'filter_id', '3': 1, '4': 1, '5': 9, '10': 'filterId'},
    const {'1': 'filter', '3': 2, '4': 1, '5': 11, '6': '.FilterPB', '9': 0, '10': 'filter'},
  ],
  '8': const [
    const {'1': 'one_of_filter'},
  ],
};

/// Descriptor for `UpdatedFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatedFilterDescriptor = $convert.base64Decode('Cg1VcGRhdGVkRmlsdGVyEhsKCWZpbHRlcl9pZBgBIAEoCVIIZmlsdGVySWQSIwoGZmlsdGVyGAIgASgLMgkuRmlsdGVyUEJIAFIGZmlsdGVyQg8KDW9uZV9vZl9maWx0ZXI=');
