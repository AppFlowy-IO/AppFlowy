///
//  Generated code. Do not modify.
//  source: code.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

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
    const {'1': 'WorkspaceNameInvalid', '2': 5},
    const {'1': 'WorkspaceIdInvalid', '2': 6},
    const {'1': 'AppColorStyleInvalid', '2': 7},
    const {'1': 'WorkspaceDescTooLong', '2': 8},
    const {'1': 'WorkspaceNameTooLong', '2': 9},
    const {'1': 'AppIdInvalid', '2': 10},
    const {'1': 'AppNameInvalid', '2': 11},
    const {'1': 'ViewNameInvalid', '2': 12},
    const {'1': 'ViewThumbnailInvalid', '2': 13},
    const {'1': 'ViewIdInvalid', '2': 14},
    const {'1': 'ViewDescTooLong', '2': 15},
    const {'1': 'ViewDataInvalid', '2': 16},
    const {'1': 'ViewNameTooLong', '2': 17},
    const {'1': 'HttpServerConnectError', '2': 18},
    const {'1': 'EmailIsEmpty', '2': 19},
    const {'1': 'EmailFormatInvalid', '2': 20},
    const {'1': 'EmailAlreadyExists', '2': 21},
    const {'1': 'PasswordIsEmpty', '2': 22},
    const {'1': 'PasswordTooLong', '2': 23},
    const {'1': 'PasswordContainsForbidCharacters', '2': 24},
    const {'1': 'PasswordFormatInvalid', '2': 25},
    const {'1': 'PasswordNotMatch', '2': 26},
    const {'1': 'UserNameTooLong', '2': 27},
    const {'1': 'UserNameContainForbiddenCharacters', '2': 28},
    const {'1': 'UserNameIsEmpty', '2': 29},
    const {'1': 'UserIdInvalid', '2': 30},
    const {'1': 'UserNotExist', '2': 31},
    const {'1': 'TextTooLong', '2': 32},
    const {'1': 'GridIdIsEmpty', '2': 33},
    const {'1': 'GridViewIdIsEmpty', '2': 34},
    const {'1': 'BlockIdIsEmpty', '2': 35},
    const {'1': 'RowIdIsEmpty', '2': 36},
    const {'1': 'OptionIdIsEmpty', '2': 37},
    const {'1': 'FieldIdIsEmpty', '2': 38},
    const {'1': 'FieldDoesNotExist', '2': 39},
    const {'1': 'SelectOptionNameIsEmpty', '2': 40},
    const {'1': 'FieldNotExists', '2': 41},
    const {'1': 'FieldInvalidOperation', '2': 42},
    const {'1': 'FilterIdIsEmpty', '2': 43},
    const {'1': 'FieldRecordNotFound', '2': 44},
    const {'1': 'TypeOptionDataIsEmpty', '2': 45},
    const {'1': 'GroupIdIsEmpty', '2': 46},
    const {'1': 'InvalidDateTimeFormat', '2': 47},
    const {'1': 'UnexpectedEmptyString', '2': 48},
    const {'1': 'InvalidData', '2': 49},
    const {'1': 'Serde', '2': 50},
    const {'1': 'ProtobufSerde', '2': 51},
    const {'1': 'OutOfBounds', '2': 52},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode('CglFcnJvckNvZGUSDAoISW50ZXJuYWwQABIUChBVc2VyVW5hdXRob3JpemVkEAISEgoOUmVjb3JkTm90Rm91bmQQAxIRCg1Vc2VySWRJc0VtcHR5EAQSGAoUV29ya3NwYWNlTmFtZUludmFsaWQQBRIWChJXb3Jrc3BhY2VJZEludmFsaWQQBhIYChRBcHBDb2xvclN0eWxlSW52YWxpZBAHEhgKFFdvcmtzcGFjZURlc2NUb29Mb25nEAgSGAoUV29ya3NwYWNlTmFtZVRvb0xvbmcQCRIQCgxBcHBJZEludmFsaWQQChISCg5BcHBOYW1lSW52YWxpZBALEhMKD1ZpZXdOYW1lSW52YWxpZBAMEhgKFFZpZXdUaHVtYm5haWxJbnZhbGlkEA0SEQoNVmlld0lkSW52YWxpZBAOEhMKD1ZpZXdEZXNjVG9vTG9uZxAPEhMKD1ZpZXdEYXRhSW52YWxpZBAQEhMKD1ZpZXdOYW1lVG9vTG9uZxAREhoKFkh0dHBTZXJ2ZXJDb25uZWN0RXJyb3IQEhIQCgxFbWFpbElzRW1wdHkQExIWChJFbWFpbEZvcm1hdEludmFsaWQQFBIWChJFbWFpbEFscmVhZHlFeGlzdHMQFRITCg9QYXNzd29yZElzRW1wdHkQFhITCg9QYXNzd29yZFRvb0xvbmcQFxIkCiBQYXNzd29yZENvbnRhaW5zRm9yYmlkQ2hhcmFjdGVycxAYEhkKFVBhc3N3b3JkRm9ybWF0SW52YWxpZBAZEhQKEFBhc3N3b3JkTm90TWF0Y2gQGhITCg9Vc2VyTmFtZVRvb0xvbmcQGxImCiJVc2VyTmFtZUNvbnRhaW5Gb3JiaWRkZW5DaGFyYWN0ZXJzEBwSEwoPVXNlck5hbWVJc0VtcHR5EB0SEQoNVXNlcklkSW52YWxpZBAeEhAKDFVzZXJOb3RFeGlzdBAfEg8KC1RleHRUb29Mb25nECASEQoNR3JpZElkSXNFbXB0eRAhEhUKEUdyaWRWaWV3SWRJc0VtcHR5ECISEgoOQmxvY2tJZElzRW1wdHkQIxIQCgxSb3dJZElzRW1wdHkQJBITCg9PcHRpb25JZElzRW1wdHkQJRISCg5GaWVsZElkSXNFbXB0eRAmEhUKEUZpZWxkRG9lc05vdEV4aXN0ECcSGwoXU2VsZWN0T3B0aW9uTmFtZUlzRW1wdHkQKBISCg5GaWVsZE5vdEV4aXN0cxApEhkKFUZpZWxkSW52YWxpZE9wZXJhdGlvbhAqEhMKD0ZpbHRlcklkSXNFbXB0eRArEhcKE0ZpZWxkUmVjb3JkTm90Rm91bmQQLBIZChVUeXBlT3B0aW9uRGF0YUlzRW1wdHkQLRISCg5Hcm91cElkSXNFbXB0eRAuEhkKFUludmFsaWREYXRlVGltZUZvcm1hdBAvEhkKFVVuZXhwZWN0ZWRFbXB0eVN0cmluZxAwEg8KC0ludmFsaWREYXRhEDESCQoFU2VyZGUQMhIRCg1Qcm90b2J1ZlNlcmRlEDMSDwoLT3V0T2ZCb3VuZHMQNA==');
