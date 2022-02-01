///
//  Generated code. Do not modify.
//  source: user_setting.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class UserPreferences extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserPreferences', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aOM<AppearanceSettings>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appearanceSetting', subBuilder: AppearanceSettings.create)
    ..hasRequiredFields = false
  ;

  UserPreferences._() : super();
  factory UserPreferences({
    $core.String? userId,
    AppearanceSettings? appearanceSetting,
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
  factory UserPreferences.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserPreferences.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserPreferences clone() => UserPreferences()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserPreferences copyWith(void Function(UserPreferences) updates) => super.copyWith((message) => updates(message as UserPreferences)) as UserPreferences; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserPreferences create() => UserPreferences._();
  UserPreferences createEmptyInstance() => create();
  static $pb.PbList<UserPreferences> createRepeated() => $pb.PbList<UserPreferences>();
  @$core.pragma('dart2js:noInline')
  static UserPreferences getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserPreferences>(create);
  static UserPreferences? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  AppearanceSettings get appearanceSetting => $_getN(1);
  @$pb.TagNumber(2)
  set appearanceSetting(AppearanceSettings v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAppearanceSetting() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppearanceSetting() => clearField(2);
  @$pb.TagNumber(2)
  AppearanceSettings ensureAppearanceSetting() => $_ensure(1);
}

class AppearanceSettings extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AppearanceSettings', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'theme')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'language')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'resetAsDefault')
    ..hasRequiredFields = false
  ;

  AppearanceSettings._() : super();
  factory AppearanceSettings({
    $core.String? theme,
    $core.String? language,
    $core.bool? resetAsDefault,
  }) {
    final _result = create();
    if (theme != null) {
      _result.theme = theme;
    }
    if (language != null) {
      _result.language = language;
    }
    if (resetAsDefault != null) {
      _result.resetAsDefault = resetAsDefault;
    }
    return _result;
  }
  factory AppearanceSettings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AppearanceSettings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AppearanceSettings clone() => AppearanceSettings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AppearanceSettings copyWith(void Function(AppearanceSettings) updates) => super.copyWith((message) => updates(message as AppearanceSettings)) as AppearanceSettings; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AppearanceSettings create() => AppearanceSettings._();
  AppearanceSettings createEmptyInstance() => create();
  static $pb.PbList<AppearanceSettings> createRepeated() => $pb.PbList<AppearanceSettings>();
  @$core.pragma('dart2js:noInline')
  static AppearanceSettings getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppearanceSettings>(create);
  static AppearanceSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get theme => $_getSZ(0);
  @$pb.TagNumber(1)
  set theme($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTheme() => $_has(0);
  @$pb.TagNumber(1)
  void clearTheme() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get language => $_getSZ(1);
  @$pb.TagNumber(2)
  set language($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLanguage() => $_has(1);
  @$pb.TagNumber(2)
  void clearLanguage() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get resetAsDefault => $_getBF(2);
  @$pb.TagNumber(3)
  set resetAsDefault($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasResetAsDefault() => $_has(2);
  @$pb.TagNumber(3)
  void clearResetAsDefault() => clearField(3);
}

