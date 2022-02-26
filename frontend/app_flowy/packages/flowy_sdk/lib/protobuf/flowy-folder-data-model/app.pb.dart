///
//  Generated code. Do not modify.
//  source: app.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'view.pb.dart' as $0;

class App extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'App', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<$0.RepeatedView>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongings', subBuilder: $0.RepeatedView.create)
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..aInt64(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..hasRequiredFields = false
  ;

  App._() : super();
  factory App({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? name,
    $core.String? desc,
    $0.RepeatedView? belongings,
    $fixnum.Int64? version,
    $fixnum.Int64? modifiedTime,
    $fixnum.Int64? createTime,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (workspaceId != null) {
      _result.workspaceId = workspaceId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (belongings != null) {
      _result.belongings = belongings;
    }
    if (version != null) {
      _result.version = version;
    }
    if (modifiedTime != null) {
      _result.modifiedTime = modifiedTime;
    }
    if (createTime != null) {
      _result.createTime = createTime;
    }
    return _result;
  }
  factory App.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory App.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  App clone() => App()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  App copyWith(void Function(App) updates) => super.copyWith((message) => updates(message as App)) as App; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static App create() => App._();
  App createEmptyInstance() => create();
  static $pb.PbList<App> createRepeated() => $pb.PbList<App>();
  @$core.pragma('dart2js:noInline')
  static App getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<App>(create);
  static App? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get desc => $_getSZ(3);
  @$pb.TagNumber(4)
  set desc($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDesc() => $_has(3);
  @$pb.TagNumber(4)
  void clearDesc() => clearField(4);

  @$pb.TagNumber(5)
  $0.RepeatedView get belongings => $_getN(4);
  @$pb.TagNumber(5)
  set belongings($0.RepeatedView v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasBelongings() => $_has(4);
  @$pb.TagNumber(5)
  void clearBelongings() => clearField(5);
  @$pb.TagNumber(5)
  $0.RepeatedView ensureBelongings() => $_ensure(4);

  @$pb.TagNumber(6)
  $fixnum.Int64 get version => $_getI64(5);
  @$pb.TagNumber(6)
  set version($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersion() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get modifiedTime => $_getI64(6);
  @$pb.TagNumber(7)
  set modifiedTime($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasModifiedTime() => $_has(6);
  @$pb.TagNumber(7)
  void clearModifiedTime() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get createTime => $_getI64(7);
  @$pb.TagNumber(8)
  set createTime($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasCreateTime() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreateTime() => clearField(8);
}

class RepeatedApp extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedApp', createEmptyInstance: create)
    ..pc<App>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: App.create)
    ..hasRequiredFields = false
  ;

  RepeatedApp._() : super();
  factory RepeatedApp({
    $core.Iterable<App>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedApp.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedApp.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedApp clone() => RepeatedApp()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedApp copyWith(void Function(RepeatedApp) updates) => super.copyWith((message) => updates(message as RepeatedApp)) as RepeatedApp; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedApp create() => RepeatedApp._();
  RepeatedApp createEmptyInstance() => create();
  static $pb.PbList<RepeatedApp> createRepeated() => $pb.PbList<RepeatedApp>();
  @$core.pragma('dart2js:noInline')
  static RepeatedApp getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedApp>(create);
  static RepeatedApp? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<App> get items => $_getList(0);
}

class CreateAppPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateAppPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<ColorStyle>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'colorStyle', subBuilder: ColorStyle.create)
    ..hasRequiredFields = false
  ;

  CreateAppPayload._() : super();
  factory CreateAppPayload({
    $core.String? workspaceId,
    $core.String? name,
    $core.String? desc,
    ColorStyle? colorStyle,
  }) {
    final _result = create();
    if (workspaceId != null) {
      _result.workspaceId = workspaceId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (colorStyle != null) {
      _result.colorStyle = colorStyle;
    }
    return _result;
  }
  factory CreateAppPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateAppPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateAppPayload clone() => CreateAppPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateAppPayload copyWith(void Function(CreateAppPayload) updates) => super.copyWith((message) => updates(message as CreateAppPayload)) as CreateAppPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateAppPayload create() => CreateAppPayload._();
  CreateAppPayload createEmptyInstance() => create();
  static $pb.PbList<CreateAppPayload> createRepeated() => $pb.PbList<CreateAppPayload>();
  @$core.pragma('dart2js:noInline')
  static CreateAppPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateAppPayload>(create);
  static CreateAppPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);

  @$pb.TagNumber(4)
  ColorStyle get colorStyle => $_getN(3);
  @$pb.TagNumber(4)
  set colorStyle(ColorStyle v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasColorStyle() => $_has(3);
  @$pb.TagNumber(4)
  void clearColorStyle() => clearField(4);
  @$pb.TagNumber(4)
  ColorStyle ensureColorStyle() => $_ensure(3);
}

class ColorStyle extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ColorStyle', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'themeColor')
    ..hasRequiredFields = false
  ;

  ColorStyle._() : super();
  factory ColorStyle({
    $core.String? themeColor,
  }) {
    final _result = create();
    if (themeColor != null) {
      _result.themeColor = themeColor;
    }
    return _result;
  }
  factory ColorStyle.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ColorStyle.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ColorStyle clone() => ColorStyle()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ColorStyle copyWith(void Function(ColorStyle) updates) => super.copyWith((message) => updates(message as ColorStyle)) as ColorStyle; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ColorStyle create() => ColorStyle._();
  ColorStyle createEmptyInstance() => create();
  static $pb.PbList<ColorStyle> createRepeated() => $pb.PbList<ColorStyle>();
  @$core.pragma('dart2js:noInline')
  static ColorStyle getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ColorStyle>(create);
  static ColorStyle? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get themeColor => $_getSZ(0);
  @$pb.TagNumber(1)
  set themeColor($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasThemeColor() => $_has(0);
  @$pb.TagNumber(1)
  void clearThemeColor() => clearField(1);
}

class CreateAppParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateAppParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<ColorStyle>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'colorStyle', subBuilder: ColorStyle.create)
    ..hasRequiredFields = false
  ;

  CreateAppParams._() : super();
  factory CreateAppParams({
    $core.String? workspaceId,
    $core.String? name,
    $core.String? desc,
    ColorStyle? colorStyle,
  }) {
    final _result = create();
    if (workspaceId != null) {
      _result.workspaceId = workspaceId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (colorStyle != null) {
      _result.colorStyle = colorStyle;
    }
    return _result;
  }
  factory CreateAppParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateAppParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateAppParams clone() => CreateAppParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateAppParams copyWith(void Function(CreateAppParams) updates) => super.copyWith((message) => updates(message as CreateAppParams)) as CreateAppParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateAppParams create() => CreateAppParams._();
  CreateAppParams createEmptyInstance() => create();
  static $pb.PbList<CreateAppParams> createRepeated() => $pb.PbList<CreateAppParams>();
  @$core.pragma('dart2js:noInline')
  static CreateAppParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateAppParams>(create);
  static CreateAppParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);

  @$pb.TagNumber(4)
  ColorStyle get colorStyle => $_getN(3);
  @$pb.TagNumber(4)
  set colorStyle(ColorStyle v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasColorStyle() => $_has(3);
  @$pb.TagNumber(4)
  void clearColorStyle() => clearField(4);
  @$pb.TagNumber(4)
  ColorStyle ensureColorStyle() => $_ensure(3);
}

class AppId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AppId', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  AppId._() : super();
  factory AppId({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory AppId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AppId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AppId clone() => AppId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AppId copyWith(void Function(AppId) updates) => super.copyWith((message) => updates(message as AppId)) as AppId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AppId create() => AppId._();
  AppId createEmptyInstance() => create();
  static $pb.PbList<AppId> createRepeated() => $pb.PbList<AppId>();
  @$core.pragma('dart2js:noInline')
  static AppId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppId>(create);
  static AppId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

enum UpdateAppPayload_OneOfName {
  name, 
  notSet
}

enum UpdateAppPayload_OneOfDesc {
  desc, 
  notSet
}

enum UpdateAppPayload_OneOfColorStyle {
  colorStyle, 
  notSet
}

enum UpdateAppPayload_OneOfIsTrash {
  isTrash, 
  notSet
}

class UpdateAppPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateAppPayload_OneOfName> _UpdateAppPayload_OneOfNameByTag = {
    2 : UpdateAppPayload_OneOfName.name,
    0 : UpdateAppPayload_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateAppPayload_OneOfDesc> _UpdateAppPayload_OneOfDescByTag = {
    3 : UpdateAppPayload_OneOfDesc.desc,
    0 : UpdateAppPayload_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateAppPayload_OneOfColorStyle> _UpdateAppPayload_OneOfColorStyleByTag = {
    4 : UpdateAppPayload_OneOfColorStyle.colorStyle,
    0 : UpdateAppPayload_OneOfColorStyle.notSet
  };
  static const $core.Map<$core.int, UpdateAppPayload_OneOfIsTrash> _UpdateAppPayload_OneOfIsTrashByTag = {
    5 : UpdateAppPayload_OneOfIsTrash.isTrash,
    0 : UpdateAppPayload_OneOfIsTrash.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateAppPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<ColorStyle>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'colorStyle', subBuilder: ColorStyle.create)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isTrash')
    ..hasRequiredFields = false
  ;

  UpdateAppPayload._() : super();
  factory UpdateAppPayload({
    $core.String? appId,
    $core.String? name,
    $core.String? desc,
    ColorStyle? colorStyle,
    $core.bool? isTrash,
  }) {
    final _result = create();
    if (appId != null) {
      _result.appId = appId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (colorStyle != null) {
      _result.colorStyle = colorStyle;
    }
    if (isTrash != null) {
      _result.isTrash = isTrash;
    }
    return _result;
  }
  factory UpdateAppPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateAppPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateAppPayload clone() => UpdateAppPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateAppPayload copyWith(void Function(UpdateAppPayload) updates) => super.copyWith((message) => updates(message as UpdateAppPayload)) as UpdateAppPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateAppPayload create() => UpdateAppPayload._();
  UpdateAppPayload createEmptyInstance() => create();
  static $pb.PbList<UpdateAppPayload> createRepeated() => $pb.PbList<UpdateAppPayload>();
  @$core.pragma('dart2js:noInline')
  static UpdateAppPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateAppPayload>(create);
  static UpdateAppPayload? _defaultInstance;

  UpdateAppPayload_OneOfName whichOneOfName() => _UpdateAppPayload_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateAppPayload_OneOfDesc whichOneOfDesc() => _UpdateAppPayload_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateAppPayload_OneOfColorStyle whichOneOfColorStyle() => _UpdateAppPayload_OneOfColorStyleByTag[$_whichOneof(2)]!;
  void clearOneOfColorStyle() => clearField($_whichOneof(2));

  UpdateAppPayload_OneOfIsTrash whichOneOfIsTrash() => _UpdateAppPayload_OneOfIsTrashByTag[$_whichOneof(3)]!;
  void clearOneOfIsTrash() => clearField($_whichOneof(3));

  @$pb.TagNumber(1)
  $core.String get appId => $_getSZ(0);
  @$pb.TagNumber(1)
  set appId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);

  @$pb.TagNumber(4)
  ColorStyle get colorStyle => $_getN(3);
  @$pb.TagNumber(4)
  set colorStyle(ColorStyle v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasColorStyle() => $_has(3);
  @$pb.TagNumber(4)
  void clearColorStyle() => clearField(4);
  @$pb.TagNumber(4)
  ColorStyle ensureColorStyle() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get isTrash => $_getBF(4);
  @$pb.TagNumber(5)
  set isTrash($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsTrash() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsTrash() => clearField(5);
}

enum UpdateAppParams_OneOfName {
  name, 
  notSet
}

enum UpdateAppParams_OneOfDesc {
  desc, 
  notSet
}

enum UpdateAppParams_OneOfColorStyle {
  colorStyle, 
  notSet
}

enum UpdateAppParams_OneOfIsTrash {
  isTrash, 
  notSet
}

class UpdateAppParams extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateAppParams_OneOfName> _UpdateAppParams_OneOfNameByTag = {
    2 : UpdateAppParams_OneOfName.name,
    0 : UpdateAppParams_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateAppParams_OneOfDesc> _UpdateAppParams_OneOfDescByTag = {
    3 : UpdateAppParams_OneOfDesc.desc,
    0 : UpdateAppParams_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateAppParams_OneOfColorStyle> _UpdateAppParams_OneOfColorStyleByTag = {
    4 : UpdateAppParams_OneOfColorStyle.colorStyle,
    0 : UpdateAppParams_OneOfColorStyle.notSet
  };
  static const $core.Map<$core.int, UpdateAppParams_OneOfIsTrash> _UpdateAppParams_OneOfIsTrashByTag = {
    5 : UpdateAppParams_OneOfIsTrash.isTrash,
    0 : UpdateAppParams_OneOfIsTrash.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateAppParams', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<ColorStyle>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'colorStyle', subBuilder: ColorStyle.create)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isTrash')
    ..hasRequiredFields = false
  ;

  UpdateAppParams._() : super();
  factory UpdateAppParams({
    $core.String? appId,
    $core.String? name,
    $core.String? desc,
    ColorStyle? colorStyle,
    $core.bool? isTrash,
  }) {
    final _result = create();
    if (appId != null) {
      _result.appId = appId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (colorStyle != null) {
      _result.colorStyle = colorStyle;
    }
    if (isTrash != null) {
      _result.isTrash = isTrash;
    }
    return _result;
  }
  factory UpdateAppParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateAppParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateAppParams clone() => UpdateAppParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateAppParams copyWith(void Function(UpdateAppParams) updates) => super.copyWith((message) => updates(message as UpdateAppParams)) as UpdateAppParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateAppParams create() => UpdateAppParams._();
  UpdateAppParams createEmptyInstance() => create();
  static $pb.PbList<UpdateAppParams> createRepeated() => $pb.PbList<UpdateAppParams>();
  @$core.pragma('dart2js:noInline')
  static UpdateAppParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateAppParams>(create);
  static UpdateAppParams? _defaultInstance;

  UpdateAppParams_OneOfName whichOneOfName() => _UpdateAppParams_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateAppParams_OneOfDesc whichOneOfDesc() => _UpdateAppParams_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateAppParams_OneOfColorStyle whichOneOfColorStyle() => _UpdateAppParams_OneOfColorStyleByTag[$_whichOneof(2)]!;
  void clearOneOfColorStyle() => clearField($_whichOneof(2));

  UpdateAppParams_OneOfIsTrash whichOneOfIsTrash() => _UpdateAppParams_OneOfIsTrashByTag[$_whichOneof(3)]!;
  void clearOneOfIsTrash() => clearField($_whichOneof(3));

  @$pb.TagNumber(1)
  $core.String get appId => $_getSZ(0);
  @$pb.TagNumber(1)
  set appId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);

  @$pb.TagNumber(4)
  ColorStyle get colorStyle => $_getN(3);
  @$pb.TagNumber(4)
  set colorStyle(ColorStyle v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasColorStyle() => $_has(3);
  @$pb.TagNumber(4)
  void clearColorStyle() => clearField(4);
  @$pb.TagNumber(4)
  ColorStyle ensureColorStyle() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get isTrash => $_getBF(4);
  @$pb.TagNumber(5)
  set isTrash($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsTrash() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsTrash() => clearField(5);
}

