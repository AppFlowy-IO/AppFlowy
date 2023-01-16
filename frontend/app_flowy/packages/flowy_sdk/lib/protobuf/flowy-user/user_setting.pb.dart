///
//  Generated code. Do not modify.
//  source: user_setting.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'user_setting.pbenum.dart';

export 'user_setting.pbenum.dart';

class UserPreferencesPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserPreferencesPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aOM<AppearanceSettingsPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appearanceSetting', subBuilder: AppearanceSettingsPB.create)
    ..hasRequiredFields = false
  ;

  UserPreferencesPB._() : super();
  factory UserPreferencesPB({
    $core.String? userId,
    AppearanceSettingsPB? appearanceSetting,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (appearanceSetting != null) {
      _result.appearanceSetting = appearanceSetting;
    }
    return _result;
  }
  factory UserPreferencesPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserPreferencesPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserPreferencesPB clone() => UserPreferencesPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserPreferencesPB copyWith(void Function(UserPreferencesPB) updates) => super.copyWith((message) => updates(message as UserPreferencesPB)) as UserPreferencesPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserPreferencesPB create() => UserPreferencesPB._();
  UserPreferencesPB createEmptyInstance() => create();
  static $pb.PbList<UserPreferencesPB> createRepeated() => $pb.PbList<UserPreferencesPB>();
  @$core.pragma('dart2js:noInline')
  static UserPreferencesPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserPreferencesPB>(create);
  static UserPreferencesPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  AppearanceSettingsPB get appearanceSetting => $_getN(1);
  @$pb.TagNumber(2)
  set appearanceSetting(AppearanceSettingsPB v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAppearanceSetting() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppearanceSetting() => clearField(2);
  @$pb.TagNumber(2)
  AppearanceSettingsPB ensureAppearanceSetting() => $_ensure(1);
}

class AppearanceSettingsPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AppearanceSettingsPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'theme')
    ..e<ThemeModePB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'themeMode', $pb.PbFieldType.OE, defaultOrMaker: ThemeModePB.Light, valueOf: ThemeModePB.valueOf, enumValues: ThemeModePB.values)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'font')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'monospaceFont')
    ..aOM<LocaleSettingsPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'locale', subBuilder: LocaleSettingsPB.create)
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'resetToDefault')
    ..m<$core.String, $core.String>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'settingKeyValue', entryClassName: 'AppearanceSettingsPB.SettingKeyValueEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS)
    ..hasRequiredFields = false
  ;

  AppearanceSettingsPB._() : super();
  factory AppearanceSettingsPB({
    $core.String? theme,
    ThemeModePB? themeMode,
    $core.String? font,
    $core.String? monospaceFont,
    LocaleSettingsPB? locale,
    $core.bool? resetToDefault,
    $core.Map<$core.String, $core.String>? settingKeyValue,
  }) {
    final _result = create();
    if (theme != null) {
      _result.theme = theme;
    }
    if (themeMode != null) {
      _result.themeMode = themeMode;
    }
    if (font != null) {
      _result.font = font;
    }
    if (monospaceFont != null) {
      _result.monospaceFont = monospaceFont;
    }
    if (locale != null) {
      _result.locale = locale;
    }
    if (resetToDefault != null) {
      _result.resetToDefault = resetToDefault;
    }
    if (settingKeyValue != null) {
      _result.settingKeyValue.addAll(settingKeyValue);
    }
    return _result;
  }
  factory AppearanceSettingsPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AppearanceSettingsPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AppearanceSettingsPB clone() => AppearanceSettingsPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AppearanceSettingsPB copyWith(void Function(AppearanceSettingsPB) updates) => super.copyWith((message) => updates(message as AppearanceSettingsPB)) as AppearanceSettingsPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AppearanceSettingsPB create() => AppearanceSettingsPB._();
  AppearanceSettingsPB createEmptyInstance() => create();
  static $pb.PbList<AppearanceSettingsPB> createRepeated() => $pb.PbList<AppearanceSettingsPB>();
  @$core.pragma('dart2js:noInline')
  static AppearanceSettingsPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppearanceSettingsPB>(create);
  static AppearanceSettingsPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get theme => $_getSZ(0);
  @$pb.TagNumber(1)
  set theme($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTheme() => $_has(0);
  @$pb.TagNumber(1)
  void clearTheme() => clearField(1);

  @$pb.TagNumber(2)
  ThemeModePB get themeMode => $_getN(1);
  @$pb.TagNumber(2)
  set themeMode(ThemeModePB v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasThemeMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearThemeMode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get font => $_getSZ(2);
  @$pb.TagNumber(3)
  set font($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFont() => $_has(2);
  @$pb.TagNumber(3)
  void clearFont() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get monospaceFont => $_getSZ(3);
  @$pb.TagNumber(4)
  set monospaceFont($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMonospaceFont() => $_has(3);
  @$pb.TagNumber(4)
  void clearMonospaceFont() => clearField(4);

  @$pb.TagNumber(5)
  LocaleSettingsPB get locale => $_getN(4);
  @$pb.TagNumber(5)
  set locale(LocaleSettingsPB v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasLocale() => $_has(4);
  @$pb.TagNumber(5)
  void clearLocale() => clearField(5);
  @$pb.TagNumber(5)
  LocaleSettingsPB ensureLocale() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.bool get resetToDefault => $_getBF(5);
  @$pb.TagNumber(6)
  set resetToDefault($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasResetToDefault() => $_has(5);
  @$pb.TagNumber(6)
  void clearResetToDefault() => clearField(6);

  @$pb.TagNumber(7)
  $core.Map<$core.String, $core.String> get settingKeyValue => $_getMap(6);
}

class LocaleSettingsPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'LocaleSettingsPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'languageCode')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'countryCode')
    ..hasRequiredFields = false
  ;

  LocaleSettingsPB._() : super();
  factory LocaleSettingsPB({
    $core.String? languageCode,
    $core.String? countryCode,
  }) {
    final _result = create();
    if (languageCode != null) {
      _result.languageCode = languageCode;
    }
    if (countryCode != null) {
      _result.countryCode = countryCode;
    }
    return _result;
  }
  factory LocaleSettingsPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocaleSettingsPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocaleSettingsPB clone() => LocaleSettingsPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocaleSettingsPB copyWith(void Function(LocaleSettingsPB) updates) => super.copyWith((message) => updates(message as LocaleSettingsPB)) as LocaleSettingsPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LocaleSettingsPB create() => LocaleSettingsPB._();
  LocaleSettingsPB createEmptyInstance() => create();
  static $pb.PbList<LocaleSettingsPB> createRepeated() => $pb.PbList<LocaleSettingsPB>();
  @$core.pragma('dart2js:noInline')
  static LocaleSettingsPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocaleSettingsPB>(create);
  static LocaleSettingsPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get languageCode => $_getSZ(0);
  @$pb.TagNumber(1)
  set languageCode($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLanguageCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearLanguageCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get countryCode => $_getSZ(1);
  @$pb.TagNumber(2)
  set countryCode($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCountryCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCountryCode() => clearField(2);
}

