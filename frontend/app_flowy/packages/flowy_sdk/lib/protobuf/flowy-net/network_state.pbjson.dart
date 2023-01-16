///
//  Generated code. Do not modify.
//  source: network_state.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use networkTypeDescriptor instead')
const NetworkType$json = const {
  '1': 'NetworkType',
  '2': const [
    const {'1': 'UnknownNetworkType', '2': 0},
    const {'1': 'Wifi', '2': 1},
    const {'1': 'Cell', '2': 2},
    const {'1': 'Ethernet', '2': 3},
    const {'1': 'Bluetooth', '2': 4},
    const {'1': 'VPN', '2': 5},
  ],
};

/// Descriptor for `NetworkType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List networkTypeDescriptor = $convert.base64Decode('CgtOZXR3b3JrVHlwZRIWChJVbmtub3duTmV0d29ya1R5cGUQABIICgRXaWZpEAESCAoEQ2VsbBACEgwKCEV0aGVybmV0EAMSDQoJQmx1ZXRvb3RoEAQSBwoDVlBOEAU=');
@$core.Deprecated('Use networkStateDescriptor instead')
const NetworkState$json = const {
  '1': 'NetworkState',
  '2': const [
    const {'1': 'ty', '3': 1, '4': 1, '5': 14, '6': '.NetworkType', '10': 'ty'},
  ],
};

/// Descriptor for `NetworkState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List networkStateDescriptor = $convert.base64Decode('CgxOZXR3b3JrU3RhdGUSHAoCdHkYASABKA4yDC5OZXR3b3JrVHlwZVICdHk=');
