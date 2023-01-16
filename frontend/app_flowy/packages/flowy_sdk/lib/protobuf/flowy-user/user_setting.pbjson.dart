///
//  Generated code. Do not modify.
//  source: user_setting.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use themeModePBDescriptor instead')
const ThemeModePB$json = const {
  '1': 'ThemeModePB',
  '2': const [
    const {'1': 'Light', '2': 0},
    const {'1': 'Dark', '2': 1},
    const {'1': 'System', '2': 2},
  ],
};

/// Descriptor for `ThemeModePB`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List themeModePBDescriptor = $convert.base64Decode('CgtUaGVtZU1vZGVQQhIJCgVMaWdodBAAEggKBERhcmsQARIKCgZTeXN0ZW0QAg==');
@$core.Deprecated('Use userPreferencesPBDescriptor instead')
const UserPreferencesPB$json = const {
  '1': 'UserPreferencesPB',
  '2': const [
    const {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    const {'1': 'appearance_setting', '3': 2, '4': 1, '5': 11, '6': '.AppearanceSettingsPB', '10': 'appearanceSetting'},
  ],
};

/// Descriptor for `UserPreferencesPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPreferencesPBDescriptor = $convert.base64Decode('ChFVc2VyUHJlZmVyZW5jZXNQQhIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSRAoSYXBwZWFyYW5jZV9zZXR0aW5nGAIgASgLMhUuQXBwZWFyYW5jZVNldHRpbmdzUEJSEWFwcGVhcmFuY2VTZXR0aW5n');
@$core.Deprecated('Use appearanceSettingsPBDescriptor instead')
const AppearanceSettingsPB$json = const {
  '1': 'AppearanceSettingsPB',
  '2': const [
    const {'1': 'theme', '3': 1, '4': 1, '5': 9, '10': 'theme'},
    const {'1': 'theme_mode', '3': 2, '4': 1, '5': 14, '6': '.ThemeModePB', '10': 'themeMode'},
    const {'1': 'font', '3': 3, '4': 1, '5': 9, '10': 'font'},
    const {'1': 'monospace_font', '3': 4, '4': 1, '5': 9, '10': 'monospaceFont'},
    const {'1': 'locale', '3': 5, '4': 1, '5': 11, '6': '.LocaleSettingsPB', '10': 'locale'},
    const {'1': 'reset_to_default', '3': 6, '4': 1, '5': 8, '10': 'resetToDefault'},
    const {'1': 'setting_key_value', '3': 7, '4': 3, '5': 11, '6': '.AppearanceSettingsPB.SettingKeyValueEntry', '10': 'settingKeyValue'},
  ],
  '3': const [AppearanceSettingsPB_SettingKeyValueEntry$json],
};

@$core.Deprecated('Use appearanceSettingsPBDescriptor instead')
const AppearanceSettingsPB_SettingKeyValueEntry$json = const {
  '1': 'SettingKeyValueEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `AppearanceSettingsPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appearanceSettingsPBDescriptor = $convert.base64Decode('ChRBcHBlYXJhbmNlU2V0dGluZ3NQQhIUCgV0aGVtZRgBIAEoCVIFdGhlbWUSKwoKdGhlbWVfbW9kZRgCIAEoDjIMLlRoZW1lTW9kZVBCUgl0aGVtZU1vZGUSEgoEZm9udBgDIAEoCVIEZm9udBIlCg5tb25vc3BhY2VfZm9udBgEIAEoCVINbW9ub3NwYWNlRm9udBIpCgZsb2NhbGUYBSABKAsyES5Mb2NhbGVTZXR0aW5nc1BCUgZsb2NhbGUSKAoQcmVzZXRfdG9fZGVmYXVsdBgGIAEoCFIOcmVzZXRUb0RlZmF1bHQSVgoRc2V0dGluZ19rZXlfdmFsdWUYByADKAsyKi5BcHBlYXJhbmNlU2V0dGluZ3NQQi5TZXR0aW5nS2V5VmFsdWVFbnRyeVIPc2V0dGluZ0tleVZhbHVlGkIKFFNldHRpbmdLZXlWYWx1ZUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');
@$core.Deprecated('Use localeSettingsPBDescriptor instead')
const LocaleSettingsPB$json = const {
  '1': 'LocaleSettingsPB',
  '2': const [
    const {'1': 'language_code', '3': 1, '4': 1, '5': 9, '10': 'languageCode'},
    const {'1': 'country_code', '3': 2, '4': 1, '5': 9, '10': 'countryCode'},
  ],
};

/// Descriptor for `LocaleSettingsPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localeSettingsPBDescriptor = $convert.base64Decode('ChBMb2NhbGVTZXR0aW5nc1BCEiMKDWxhbmd1YWdlX2NvZGUYASABKAlSDGxhbmd1YWdlQ29kZRIhCgxjb3VudHJ5X2NvZGUYAiABKAlSC2NvdW50cnlDb2Rl');
