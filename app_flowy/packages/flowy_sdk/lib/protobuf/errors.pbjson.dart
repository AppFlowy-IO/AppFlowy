///
//  Generated code. Do not modify.
//  source: errors.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;
const UserErrorCode$json = const {
  '1': 'UserErrorCode',
  '2': const [
    const {'1': 'Unknown', '2': 0},
    const {'1': 'DatabaseInitFailed', '2': 1},
    const {'1': 'DatabaseWriteLocked', '2': 2},
    const {'1': 'DatabaseReadLocked', '2': 3},
    const {'1': 'DatabaseUserDidNotMatch', '2': 4},
    const {'1': 'DatabaseInternalError', '2': 5},
    const {'1': 'UserNotLoginYet', '2': 10},
    const {'1': 'ReadCurrentIdFailed', '2': 11},
    const {'1': 'WriteCurrentIdFailed', '2': 12},
    const {'1': 'EmailInvalid', '2': 20},
    const {'1': 'PasswordInvalid', '2': 21},
    const {'1': 'UserNameInvalid', '2': 22},
  ],
};

const UserError$json = const {
  '1': 'UserError',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.UserErrorCode', '10': 'code'},
    const {'1': 'msg', '3': 2, '4': 1, '5': 9, '10': 'msg'},
  ],
};

