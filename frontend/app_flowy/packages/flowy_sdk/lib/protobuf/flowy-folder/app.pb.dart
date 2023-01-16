///
//  Generated code. Do not modify.
//  source: app.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'view.pb.dart' as $0;

class AppPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AppPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<$0.RepeatedViewPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongings', subBuilder: $0.RepeatedViewPB.create)
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..aInt64(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..hasRequiredFields = false
  ;

  AppPB._() : super();
  factory AppPB({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? name,
    $core.String? desc,
    $0.RepeatedViewPB? belongings,
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
  factory AppPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AppPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AppPB clone() => AppPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AppPB copyWith(void Function(AppPB) updates) => super.copyWith((message) => updates(message as AppPB)) as AppPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AppPB create() => AppPB._();
  AppPB createEmptyInstance() => create();
  static $pb.PbList<AppPB> createRepeated() => $pb.PbList<AppPB>();
  @$core.pragma('dart2js:noInline')
  static AppPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppPB>(create);
  static AppPB? _defaultInstance;

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
  $0.RepeatedViewPB get belongings => $_getN(4);
  @$pb.TagNumber(5)
  set belongings($0.RepeatedViewPB v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasBelongings() => $_has(4);
  @$pb.TagNumber(5)
  void clearBelongings() => clearField(5);
  @$pb.TagNumber(5)
  $0.RepeatedViewPB ensureBelongings() => $_ensure(4);

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

class RepeatedAppPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedAppPB', createEmptyInstance: create)
    ..pc<AppPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: AppPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedAppPB._() : super();
  factory RepeatedAppPB({
    $core.Iterable<AppPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedAppPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedAppPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedAppPB clone() => RepeatedAppPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedAppPB copyWith(void Function(RepeatedAppPB) updates) => super.copyWith((message) => updates(message as RepeatedAppPB)) as RepeatedAppPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedAppPB create() => RepeatedAppPB._();
  RepeatedAppPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedAppPB> createRepeated() => $pb.PbList<RepeatedAppPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedAppPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedAppPB>(create);
  static RepeatedAppPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<AppPB> get items => $_getList(0);
}

class CreateAppPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateAppPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<ColorStylePB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'colorStyle', subBuilder: ColorStylePB.create)
    ..hasRequiredFields = false
  ;

  CreateAppPayloadPB._() : super();
  factory CreateAppPayloadPB({
    $core.String? workspaceId,
    $core.String? name,
    $core.String? desc,
    ColorStylePB? colorStyle,
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
  factory CreateAppPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateAppPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateAppPayloadPB clone() => CreateAppPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateAppPayloadPB copyWith(void Function(CreateAppPayloadPB) updates) => super.copyWith((message) => updates(message as CreateAppPayloadPB)) as CreateAppPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateAppPayloadPB create() => CreateAppPayloadPB._();
  CreateAppPayloadPB createEmptyInstance() => create();
  static $pb.PbList<CreateAppPayloadPB> createRepeated() => $pb.PbList<CreateAppPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static CreateAppPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateAppPayloadPB>(create);
  static CreateAppPayloadPB? _defaultInstance;

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
  ColorStylePB get colorStyle => $_getN(3);
  @$pb.TagNumber(4)
  set colorStyle(ColorStylePB v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasColorStyle() => $_has(3);
  @$pb.TagNumber(4)
  void clearColorStyle() => clearField(4);
  @$pb.TagNumber(4)
  ColorStylePB ensureColorStyle() => $_ensure(3);
}

class ColorStylePB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ColorStylePB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'themeColor')
    ..hasRequiredFields = false
  ;

  ColorStylePB._() : super();
  factory ColorStylePB({
    $core.String? themeColor,
  }) {
    final _result = create();
    if (themeColor != null) {
      _result.themeColor = themeColor;
    }
    return _result;
  }
  factory ColorStylePB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ColorStylePB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ColorStylePB clone() => ColorStylePB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ColorStylePB copyWith(void Function(ColorStylePB) updates) => super.copyWith((message) => updates(message as ColorStylePB)) as ColorStylePB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ColorStylePB create() => ColorStylePB._();
  ColorStylePB createEmptyInstance() => create();
  static $pb.PbList<ColorStylePB> createRepeated() => $pb.PbList<ColorStylePB>();
  @$core.pragma('dart2js:noInline')
  static ColorStylePB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ColorStylePB>(create);
  static ColorStylePB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get themeColor => $_getSZ(0);
  @$pb.TagNumber(1)
  set themeColor($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasThemeColor() => $_has(0);
  @$pb.TagNumber(1)
  void clearThemeColor() => clearField(1);
}

class AppIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AppIdPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  AppIdPB._() : super();
  factory AppIdPB({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory AppIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AppIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AppIdPB clone() => AppIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AppIdPB copyWith(void Function(AppIdPB) updates) => super.copyWith((message) => updates(message as AppIdPB)) as AppIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AppIdPB create() => AppIdPB._();
  AppIdPB createEmptyInstance() => create();
  static $pb.PbList<AppIdPB> createRepeated() => $pb.PbList<AppIdPB>();
  @$core.pragma('dart2js:noInline')
  static AppIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppIdPB>(create);
  static AppIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

enum UpdateAppPayloadPB_OneOfName {
  name, 
  notSet
}

enum UpdateAppPayloadPB_OneOfDesc {
  desc, 
  notSet
}

enum UpdateAppPayloadPB_OneOfColorStyle {
  colorStyle, 
  notSet
}

enum UpdateAppPayloadPB_OneOfIsTrash {
  isTrash, 
  notSet
}

class UpdateAppPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateAppPayloadPB_OneOfName> _UpdateAppPayloadPB_OneOfNameByTag = {
    2 : UpdateAppPayloadPB_OneOfName.name,
    0 : UpdateAppPayloadPB_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateAppPayloadPB_OneOfDesc> _UpdateAppPayloadPB_OneOfDescByTag = {
    3 : UpdateAppPayloadPB_OneOfDesc.desc,
    0 : UpdateAppPayloadPB_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateAppPayloadPB_OneOfColorStyle> _UpdateAppPayloadPB_OneOfColorStyleByTag = {
    4 : UpdateAppPayloadPB_OneOfColorStyle.colorStyle,
    0 : UpdateAppPayloadPB_OneOfColorStyle.notSet
  };
  static const $core.Map<$core.int, UpdateAppPayloadPB_OneOfIsTrash> _UpdateAppPayloadPB_OneOfIsTrashByTag = {
    5 : UpdateAppPayloadPB_OneOfIsTrash.isTrash,
    0 : UpdateAppPayloadPB_OneOfIsTrash.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateAppPayloadPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<ColorStylePB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'colorStyle', subBuilder: ColorStylePB.create)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isTrash')
    ..hasRequiredFields = false
  ;

  UpdateAppPayloadPB._() : super();
  factory UpdateAppPayloadPB({
    $core.String? appId,
    $core.String? name,
    $core.String? desc,
    ColorStylePB? colorStyle,
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
  factory UpdateAppPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateAppPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateAppPayloadPB clone() => UpdateAppPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateAppPayloadPB copyWith(void Function(UpdateAppPayloadPB) updates) => super.copyWith((message) => updates(message as UpdateAppPayloadPB)) as UpdateAppPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateAppPayloadPB create() => UpdateAppPayloadPB._();
  UpdateAppPayloadPB createEmptyInstance() => create();
  static $pb.PbList<UpdateAppPayloadPB> createRepeated() => $pb.PbList<UpdateAppPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static UpdateAppPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateAppPayloadPB>(create);
  static UpdateAppPayloadPB? _defaultInstance;

  UpdateAppPayloadPB_OneOfName whichOneOfName() => _UpdateAppPayloadPB_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateAppPayloadPB_OneOfDesc whichOneOfDesc() => _UpdateAppPayloadPB_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateAppPayloadPB_OneOfColorStyle whichOneOfColorStyle() => _UpdateAppPayloadPB_OneOfColorStyleByTag[$_whichOneof(2)]!;
  void clearOneOfColorStyle() => clearField($_whichOneof(2));

  UpdateAppPayloadPB_OneOfIsTrash whichOneOfIsTrash() => _UpdateAppPayloadPB_OneOfIsTrashByTag[$_whichOneof(3)]!;
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
  ColorStylePB get colorStyle => $_getN(3);
  @$pb.TagNumber(4)
  set colorStyle(ColorStylePB v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasColorStyle() => $_has(3);
  @$pb.TagNumber(4)
  void clearColorStyle() => clearField(4);
  @$pb.TagNumber(4)
  ColorStylePB ensureColorStyle() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get isTrash => $_getBF(4);
  @$pb.TagNumber(5)
  set isTrash($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsTrash() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsTrash() => clearField(5);
}

