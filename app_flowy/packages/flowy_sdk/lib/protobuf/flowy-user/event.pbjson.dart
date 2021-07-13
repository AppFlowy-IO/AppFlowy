///
//  Generated code. Do not modify.
//  source: event.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userEventDescriptor instead')
const UserEvent$json = const {
  '1': 'UserEvent',
  '2': const [
    const {'1': 'GetStatus', '2': 0},
    const {'1': 'SignIn', '2': 1},
    const {'1': 'SignUp', '2': 2},
    const {'1': 'SignOut', '2': 3},
  ],
};

/// Descriptor for `UserEvent`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List userEventDescriptor = $convert.base64Decode('CglVc2VyRXZlbnQSDQoJR2V0U3RhdHVzEAASCgoGU2lnbkluEAESCgoGU2lnblVwEAISCwoHU2lnbk91dBAD');
