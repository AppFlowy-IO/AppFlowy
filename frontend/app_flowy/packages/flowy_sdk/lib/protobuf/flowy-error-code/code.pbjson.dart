///
//  Generated code. Do not modify.
//  source: code.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use errorCodeDescriptor instead')
const ErrorCode$json = const {
  '1': 'ErrorCode',
  '2': const [
    const {'1': 'Internal', '2': 0},
    const {'1': 'UserUnauthorized', '2': 2},
    const {'1': 'RecordNotFound', '2': 3},
    const {'1': 'WorkspaceNameInvalid', '2': 100},
    const {'1': 'WorkspaceIdInvalid', '2': 101},
    const {'1': 'AppColorStyleInvalid', '2': 102},
    const {'1': 'WorkspaceDescTooLong', '2': 103},
    const {'1': 'WorkspaceNameTooLong', '2': 104},
    const {'1': 'AppIdInvalid', '2': 110},
    const {'1': 'AppNameInvalid', '2': 111},
    const {'1': 'ViewNameInvalid', '2': 120},
    const {'1': 'ViewThumbnailInvalid', '2': 121},
    const {'1': 'ViewIdInvalid', '2': 122},
    const {'1': 'ViewDescTooLong', '2': 123},
    const {'1': 'ViewDataInvalid', '2': 124},
    const {'1': 'ViewNameTooLong', '2': 125},
    const {'1': 'ConnectError', '2': 200},
    const {'1': 'EmailIsEmpty', '2': 300},
    const {'1': 'EmailFormatInvalid', '2': 301},
    const {'1': 'EmailAlreadyExists', '2': 302},
    const {'1': 'PasswordIsEmpty', '2': 303},
    const {'1': 'PasswordTooLong', '2': 304},
    const {'1': 'PasswordContainsForbidCharacters', '2': 305},
    const {'1': 'PasswordFormatInvalid', '2': 306},
    const {'1': 'PasswordNotMatch', '2': 307},
    const {'1': 'UserNameTooLong', '2': 308},
    const {'1': 'UserNameContainForbiddenCharacters', '2': 309},
    const {'1': 'UserNameIsEmpty', '2': 310},
    const {'1': 'UserIdInvalid', '2': 311},
    const {'1': 'UserNotExist', '2': 312},
    const {'1': 'TextTooLong', '2': 400},
    const {'1': 'BlockIdIsEmpty', '2': 401},
    const {'1': 'RowIdIsEmpty', '2': 402},
    const {'1': 'GridIdIsEmpty', '2': 403},
    const {'1': 'InvalidData', '2': 404},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSDAoISW50ZXJuYWwQABIUChBVc2VyVW5hdXRob3JpemVkEAISEgoOUmVjb3JkTm90Rm91bmQQAxIYChRXb3Jrc3BhY2VOYW1lSW52YWxpZBBkEhYKEldvcmtzcGFjZUlkSW52YWxpZBBlEhgKFEFwcENvbG9yU3R5bGVJbnZhbGlkEGYSGAoUV29ya3NwYWNlRGVzY1Rvb0xvbmcQZxIYChRXb3Jrc3BhY2VOYW1lVG9vTG9uZxBoEhAKDEFwcElkSW52YWxpZBBuEhIKDkFwcE5hbWVJbnZhbGlkEG8SEwoPVmlld05hbWVJbnZhbGlkEHgSGAoUVmlld1RodW1ibmFpbEludmFsaWQQeRIRCg1WaWV3SWRJbnZhbGlkEHoSEwoPVmlld0Rlc2NUb29Mb25nEHsSEwoPVmlld0RhdGFJbnZhbGlkEHwSEwoPVmlld05hbWVUb29Mb25nEH0SEQoMQ29ubmVjdEVycm9yEMgBEhEKDEVtYWlsSXNFbXB0eRCsAhIXChJFbWFpbEZvcm1hdEludmFsaWQQrQISFwoSRW1haWxBbHJlYWR5RXhpc3RzEK4CEhQKD1Bhc3N3b3JkSXNFbXB0eRCvAhIUCg9QYXNzd29yZFRvb0xvbmcQsAISJQogUGFzc3dvcmRDb250YWluc0ZvcmJpZENoYXJhY3RlcnMQsQISGgoVUGFzc3dvcmRGb3JtYXRJbnZhbGlkELICEhUKEFBhc3N3b3JkTm90TWF0Y2gQswISFAoPVXNlck5hbWVUb29Mb25nELQCEicKIlVzZXJOYW1lQ29udGFpbkZvcmJpZGRlbkNoYXJhY3RlcnMQtQISFAoPVXNlck5hbWVJc0VtcHR5ELYCEhIKDVVzZXJJZEludmFsaWQQtwISEQoMVXNlck5vdEV4aXN0ELgCEhAKC1RleHRUb29Mb25nEJADEhMKDkJsb2NrSWRJc0VtcHR5EJEDEhEKDFJvd0lkSXNFbXB0eRCSAxISCg1HcmlkSWRJc0VtcHR5EJMDEhAKC0ludmFsaWREYXRhEJQD');
