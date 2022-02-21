///
//  Generated code. Do not modify.
//  source: user_setting.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use userPreferencesDescriptor instead')
const UserPreferences$json = const {
  '1': 'UserPreferences',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'appearance_setting', '3': 2, '4': 1, '5': 11, '6': '.AppearanceSettings', '10': 'appearanceSetting'},
  ],
};

/// Descriptor for `UserPreferences`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPreferencesDescriptor = $convert.base64Decode('Cg9Vc2VyUHJlZmVyZW5jZXMSFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEkIKEmFwcGVhcmFuY2Vfc2V0dGluZxgCIAEoCzITLkFwcGVhcmFuY2VTZXR0aW5nc1IRYXBwZWFyYW5jZVNldHRpbmc=');
@$core.Deprecated('Use appearanceSettingsDescriptor instead')
const AppearanceSettings$json = const {
  '1': 'AppearanceSettings',
  '2': const [
    const {'1': 'theme', '3': 1, '4': 1, '5': 9, '10': 'theme'},
    const {'1': 'locale', '3': 2, '4': 1, '5': 11, '6': '.LocaleSettings', '10': 'locale'},
    const {'1': 'reset_as_default', '3': 3, '4': 1, '5': 8, '10': 'resetAsDefault'},
  ],
};

/// Descriptor for `AppearanceSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appearanceSettingsDescriptor = $convert.base64Decode('ChJBcHBlYXJhbmNlU2V0dGluZ3MSFAoFdGhlbWUYASABKAlSBXRoZW1lEicKBmxvY2FsZRgCIAEoCzIPLkxvY2FsZVNldHRpbmdzUgZsb2NhbGUSKAoQcmVzZXRfYXNfZGVmYXVsdBgDIAEoCFIOcmVzZXRBc0RlZmF1bHQ=');
@$core.Deprecated('Use localeSettingsDescriptor instead')
const LocaleSettings$json = const {
  '1': 'LocaleSettings',
  '2': const [
    const {'1': 'language_code', '3': 1, '4': 1, '5': 9, '10': 'languageCode'},
    const {'1': 'country_code', '3': 2, '4': 1, '5': 9, '10': 'countryCode'},
  ],
};

/// Descriptor for `LocaleSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localeSettingsDescriptor = $convert.base64Decode('Cg5Mb2NhbGVTZXR0aW5ncxIjCg1sYW5ndWFnZV9jb2RlGAEgASgJUgxsYW5ndWFnZUNvZGUSIQoMY291bnRyeV9jb2RlGAIgASgJUgtjb3VudHJ5Q29kZQ==');
