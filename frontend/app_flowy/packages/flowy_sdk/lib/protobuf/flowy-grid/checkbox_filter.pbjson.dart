///
//  Generated code. Do not modify.
//  source: checkbox_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use checkboxFilterConditionPBDescriptor instead')
const CheckboxFilterConditionPB$json = const {
  '1': 'CheckboxFilterConditionPB',
  '2': const [
    const {'1': 'IsChecked', '2': 0},
    const {'1': 'IsUnChecked', '2': 1},
  ],
};

/// Descriptor for `CheckboxFilterConditionPB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List checkboxFilterConditionPBDescriptor = $convert.base64Decode('ChlDaGVja2JveEZpbHRlckNvbmRpdGlvblBCEg0KCUlzQ2hlY2tlZBAAEg8KC0lzVW5DaGVja2VkEAE=');
@$core.Deprecated('Use checkboxFilterPBDescriptor instead')
const CheckboxFilterPB$json = const {
  '1': 'CheckboxFilterPB',
  '2': const [
    const {'1': 'condition', '3': 1, '4': 1, '5': 14, '6': '.CheckboxFilterConditionPB', '10': 'condition'},
  ],
};

/// Descriptor for `CheckboxFilterPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkboxFilterPBDescriptor = $convert.base64Decode('ChBDaGVja2JveEZpbHRlclBCEjgKCWNvbmRpdGlvbhgBIAEoDjIaLkNoZWNrYm94RmlsdGVyQ29uZGl0aW9uUEJSCWNvbmRpdGlvbg==');
