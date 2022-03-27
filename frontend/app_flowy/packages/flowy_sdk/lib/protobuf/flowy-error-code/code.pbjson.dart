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
    const {'1': 'UserIdIsEmpty', '2': 4},
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
    const {'1': 'GridIdIsEmpty', '2': 410},
    const {'1': 'BlockIdIsEmpty', '2': 420},
    const {'1': 'RowIdIsEmpty', '2': 430},
    const {'1': 'FieldIdIsEmpty', '2': 440},
    const {'1': 'FieldDoesNotExist', '2': 441},
    const {'1': 'TypeOptionDataIsEmpty', '2': 450},
    const {'1': 'InvalidData', '2': 500},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSDAoISW50ZXJuYWwQABIUChBVc2VyVW5hdXRob3JpemVkEAISEgoOUmVjb3JkTm90Rm91bmQQAxIRCg1Vc2VySWRJc0VtcHR5EAQSGAoUV29ya3NwYWNlTmFtZUludmFsaWQQZBIWChJXb3Jrc3BhY2VJZEludmFsaWQQZRIYChRBcHBDb2xvclN0eWxlSW52YWxpZBBmEhgKFFdvcmtzcGFjZURlc2NUb29Mb25nEGcSGAoUV29ya3NwYWNlTmFtZVRvb0xvbmcQaBIQCgxBcHBJZEludmFsaWQQbhISCg5BcHBOYW1lSW52YWxpZBBvEhMKD1ZpZXdOYW1lSW52YWxpZBB4EhgKFFZpZXdUaHVtYm5haWxJbnZhbGlkEHkSEQoNVmlld0lkSW52YWxpZBB6EhMKD1ZpZXdEZXNjVG9vTG9uZxB7EhMKD1ZpZXdEYXRhSW52YWxpZBB8EhMKD1ZpZXdOYW1lVG9vTG9uZxB9EhEKDENvbm5lY3RFcnJvchDIARIRCgxFbWFpbElzRW1wdHkQrAISFwoSRW1haWxGb3JtYXRJbnZhbGlkEK0CEhcKEkVtYWlsQWxyZWFkeUV4aXN0cxCuAhIUCg9QYXNzd29yZElzRW1wdHkQrwISFAoPUGFzc3dvcmRUb29Mb25nELACEiUKIFBhc3N3b3JkQ29udGFpbnNGb3JiaWRDaGFyYWN0ZXJzELECEhoKFVBhc3N3b3JkRm9ybWF0SW52YWxpZBCyAhIVChBQYXNzd29yZE5vdE1hdGNoELMCEhQKD1VzZXJOYW1lVG9vTG9uZxC0AhInCiJVc2VyTmFtZUNvbnRhaW5Gb3JiaWRkZW5DaGFyYWN0ZXJzELUCEhQKD1VzZXJOYW1lSXNFbXB0eRC2AhISCg1Vc2VySWRJbnZhbGlkELcCEhEKDFVzZXJOb3RFeGlzdBC4AhIQCgtUZXh0VG9vTG9uZxCQAxISCg1HcmlkSWRJc0VtcHR5EJoDEhMKDkJsb2NrSWRJc0VtcHR5EKQDEhEKDFJvd0lkSXNFbXB0eRCuAxITCg5GaWVsZElkSXNFbXB0eRC4AxIWChFGaWVsZERvZXNOb3RFeGlzdBC5AxIaChVUeXBlT3B0aW9uRGF0YUlzRW1wdHkQwgMSEAoLSW52YWxpZERhdGEQ9AM=');
