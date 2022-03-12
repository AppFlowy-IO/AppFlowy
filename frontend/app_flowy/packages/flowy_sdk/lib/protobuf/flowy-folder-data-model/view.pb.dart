///
//  Generated code. Do not modify.
//  source: view.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'view.pbenum.dart';

export 'view.pbenum.dart';

class View extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'View', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<ViewDataType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', $pb.PbFieldType.OE, defaultOrMaker: ViewDataType.TextBlock, valueOf: ViewDataType.valueOf, enumValues: ViewDataType.values)
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..aOM<RepeatedView>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongings', subBuilder: RepeatedView.create)
    ..aInt64(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..aOS(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extData')
    ..aOS(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..a<$core.int>(12, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pluginType', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  View._() : super();
  factory View({
    $core.String? id,
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    ViewDataType? dataType,
    $fixnum.Int64? version,
    RepeatedView? belongings,
    $fixnum.Int64? modifiedTime,
    $fixnum.Int64? createTime,
    $core.String? extData,
    $core.String? thumbnail,
    $core.int? pluginType,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (belongToId != null) {
      _result.belongToId = belongToId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (dataType != null) {
      _result.dataType = dataType;
    }
    if (version != null) {
      _result.version = version;
    }
    if (belongings != null) {
      _result.belongings = belongings;
    }
    if (modifiedTime != null) {
      _result.modifiedTime = modifiedTime;
    }
    if (createTime != null) {
      _result.createTime = createTime;
    }
    if (extData != null) {
      _result.extData = extData;
    }
    if (thumbnail != null) {
      _result.thumbnail = thumbnail;
    }
    if (pluginType != null) {
      _result.pluginType = pluginType;
    }
    return _result;
  }
  factory View.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory View.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  View clone() => View()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  View copyWith(void Function(View) updates) => super.copyWith((message) => updates(message as View)) as View; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static View create() => View._();
  View createEmptyInstance() => create();
  static $pb.PbList<View> createRepeated() => $pb.PbList<View>();
  @$core.pragma('dart2js:noInline')
  static View getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<View>(create);
  static View? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get belongToId => $_getSZ(1);
  @$pb.TagNumber(2)
  set belongToId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBelongToId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBelongToId() => clearField(2);

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
  ViewDataType get dataType => $_getN(4);
  @$pb.TagNumber(5)
  set dataType(ViewDataType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDataType() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataType() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get version => $_getI64(5);
  @$pb.TagNumber(6)
  set version($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersion() => clearField(6);

  @$pb.TagNumber(7)
  RepeatedView get belongings => $_getN(6);
  @$pb.TagNumber(7)
  set belongings(RepeatedView v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasBelongings() => $_has(6);
  @$pb.TagNumber(7)
  void clearBelongings() => clearField(7);
  @$pb.TagNumber(7)
  RepeatedView ensureBelongings() => $_ensure(6);

  @$pb.TagNumber(8)
  $fixnum.Int64 get modifiedTime => $_getI64(7);
  @$pb.TagNumber(8)
  set modifiedTime($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasModifiedTime() => $_has(7);
  @$pb.TagNumber(8)
  void clearModifiedTime() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get createTime => $_getI64(8);
  @$pb.TagNumber(9)
  set createTime($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasCreateTime() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreateTime() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get extData => $_getSZ(9);
  @$pb.TagNumber(10)
  set extData($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasExtData() => $_has(9);
  @$pb.TagNumber(10)
  void clearExtData() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get thumbnail => $_getSZ(10);
  @$pb.TagNumber(11)
  set thumbnail($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasThumbnail() => $_has(10);
  @$pb.TagNumber(11)
  void clearThumbnail() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get pluginType => $_getIZ(11);
  @$pb.TagNumber(12)
  set pluginType($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasPluginType() => $_has(11);
  @$pb.TagNumber(12)
  void clearPluginType() => clearField(12);
}

class RepeatedView extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedView', createEmptyInstance: create)
    ..pc<View>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: View.create)
    ..hasRequiredFields = false
  ;

  RepeatedView._() : super();
  factory RepeatedView({
    $core.Iterable<View>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedView.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedView.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedView clone() => RepeatedView()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedView copyWith(void Function(RepeatedView) updates) => super.copyWith((message) => updates(message as RepeatedView)) as RepeatedView; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedView create() => RepeatedView._();
  RepeatedView createEmptyInstance() => create();
  static $pb.PbList<RepeatedView> createRepeated() => $pb.PbList<RepeatedView>();
  @$core.pragma('dart2js:noInline')
  static RepeatedView getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedView>(create);
  static RepeatedView? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<View> get items => $_getList(0);
}

enum CreateViewPayload_OneOfThumbnail {
  thumbnail, 
  notSet
}

class CreateViewPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateViewPayload_OneOfThumbnail> _CreateViewPayload_OneOfThumbnailByTag = {
    4 : CreateViewPayload_OneOfThumbnail.thumbnail,
    0 : CreateViewPayload_OneOfThumbnail.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateViewPayload', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..e<ViewDataType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', $pb.PbFieldType.OE, defaultOrMaker: ViewDataType.TextBlock, valueOf: ViewDataType.valueOf, enumValues: ViewDataType.values)
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extData')
    ..a<$core.int>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pluginType', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  CreateViewPayload._() : super();
  factory CreateViewPayload({
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    ViewDataType? dataType,
    $core.String? extData,
    $core.int? pluginType,
  }) {
    final _result = create();
    if (belongToId != null) {
      _result.belongToId = belongToId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (thumbnail != null) {
      _result.thumbnail = thumbnail;
    }
    if (dataType != null) {
      _result.dataType = dataType;
    }
    if (extData != null) {
      _result.extData = extData;
    }
    if (pluginType != null) {
      _result.pluginType = pluginType;
    }
    return _result;
  }
  factory CreateViewPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateViewPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateViewPayload clone() => CreateViewPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateViewPayload copyWith(void Function(CreateViewPayload) updates) => super.copyWith((message) => updates(message as CreateViewPayload)) as CreateViewPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateViewPayload create() => CreateViewPayload._();
  CreateViewPayload createEmptyInstance() => create();
  static $pb.PbList<CreateViewPayload> createRepeated() => $pb.PbList<CreateViewPayload>();
  @$core.pragma('dart2js:noInline')
  static CreateViewPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateViewPayload>(create);
  static CreateViewPayload? _defaultInstance;

  CreateViewPayload_OneOfThumbnail whichOneOfThumbnail() => _CreateViewPayload_OneOfThumbnailByTag[$_whichOneof(0)]!;
  void clearOneOfThumbnail() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get belongToId => $_getSZ(0);
  @$pb.TagNumber(1)
  set belongToId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBelongToId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBelongToId() => clearField(1);

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
  $core.String get thumbnail => $_getSZ(3);
  @$pb.TagNumber(4)
  set thumbnail($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasThumbnail() => $_has(3);
  @$pb.TagNumber(4)
  void clearThumbnail() => clearField(4);

  @$pb.TagNumber(5)
  ViewDataType get dataType => $_getN(4);
  @$pb.TagNumber(5)
  set dataType(ViewDataType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDataType() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataType() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get extData => $_getSZ(5);
  @$pb.TagNumber(6)
  set extData($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasExtData() => $_has(5);
  @$pb.TagNumber(6)
  void clearExtData() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get pluginType => $_getIZ(6);
  @$pb.TagNumber(7)
  set pluginType($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasPluginType() => $_has(6);
  @$pb.TagNumber(7)
  void clearPluginType() => clearField(7);
}

class CreateViewParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateViewParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..e<ViewDataType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', $pb.PbFieldType.OE, defaultOrMaker: ViewDataType.TextBlock, valueOf: ViewDataType.valueOf, enumValues: ViewDataType.values)
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extData')
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..a<$core.int>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pluginType', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  CreateViewParams._() : super();
  factory CreateViewParams({
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    ViewDataType? dataType,
    $core.String? extData,
    $core.String? viewId,
    $core.String? data,
    $core.int? pluginType,
  }) {
    final _result = create();
    if (belongToId != null) {
      _result.belongToId = belongToId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (thumbnail != null) {
      _result.thumbnail = thumbnail;
    }
    if (dataType != null) {
      _result.dataType = dataType;
    }
    if (extData != null) {
      _result.extData = extData;
    }
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (data != null) {
      _result.data = data;
    }
    if (pluginType != null) {
      _result.pluginType = pluginType;
    }
    return _result;
  }
  factory CreateViewParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateViewParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateViewParams clone() => CreateViewParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateViewParams copyWith(void Function(CreateViewParams) updates) => super.copyWith((message) => updates(message as CreateViewParams)) as CreateViewParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateViewParams create() => CreateViewParams._();
  CreateViewParams createEmptyInstance() => create();
  static $pb.PbList<CreateViewParams> createRepeated() => $pb.PbList<CreateViewParams>();
  @$core.pragma('dart2js:noInline')
  static CreateViewParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateViewParams>(create);
  static CreateViewParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get belongToId => $_getSZ(0);
  @$pb.TagNumber(1)
  set belongToId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBelongToId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBelongToId() => clearField(1);

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
  $core.String get thumbnail => $_getSZ(3);
  @$pb.TagNumber(4)
  set thumbnail($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasThumbnail() => $_has(3);
  @$pb.TagNumber(4)
  void clearThumbnail() => clearField(4);

  @$pb.TagNumber(5)
  ViewDataType get dataType => $_getN(4);
  @$pb.TagNumber(5)
  set dataType(ViewDataType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDataType() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataType() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get extData => $_getSZ(5);
  @$pb.TagNumber(6)
  set extData($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasExtData() => $_has(5);
  @$pb.TagNumber(6)
  void clearExtData() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get viewId => $_getSZ(6);
  @$pb.TagNumber(7)
  set viewId($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasViewId() => $_has(6);
  @$pb.TagNumber(7)
  void clearViewId() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get data => $_getSZ(7);
  @$pb.TagNumber(8)
  set data($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasData() => $_has(7);
  @$pb.TagNumber(8)
  void clearData() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get pluginType => $_getIZ(8);
  @$pb.TagNumber(9)
  set pluginType($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasPluginType() => $_has(8);
  @$pb.TagNumber(9)
  void clearPluginType() => clearField(9);
}

class ViewId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewId', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  ViewId._() : super();
  factory ViewId({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory ViewId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewId clone() => ViewId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewId copyWith(void Function(ViewId) updates) => super.copyWith((message) => updates(message as ViewId)) as ViewId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewId create() => ViewId._();
  ViewId createEmptyInstance() => create();
  static $pb.PbList<ViewId> createRepeated() => $pb.PbList<ViewId>();
  @$core.pragma('dart2js:noInline')
  static ViewId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewId>(create);
  static ViewId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

class RepeatedViewId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedViewId', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items')
    ..hasRequiredFields = false
  ;

  RepeatedViewId._() : super();
  factory RepeatedViewId({
    $core.Iterable<$core.String>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedViewId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedViewId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedViewId clone() => RepeatedViewId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedViewId copyWith(void Function(RepeatedViewId) updates) => super.copyWith((message) => updates(message as RepeatedViewId)) as RepeatedViewId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedViewId create() => RepeatedViewId._();
  RepeatedViewId createEmptyInstance() => create();
  static $pb.PbList<RepeatedViewId> createRepeated() => $pb.PbList<RepeatedViewId>();
  @$core.pragma('dart2js:noInline')
  static RepeatedViewId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedViewId>(create);
  static RepeatedViewId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get items => $_getList(0);
}

enum UpdateViewPayload_OneOfName {
  name, 
  notSet
}

enum UpdateViewPayload_OneOfDesc {
  desc, 
  notSet
}

enum UpdateViewPayload_OneOfThumbnail {
  thumbnail, 
  notSet
}

class UpdateViewPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateViewPayload_OneOfName> _UpdateViewPayload_OneOfNameByTag = {
    2 : UpdateViewPayload_OneOfName.name,
    0 : UpdateViewPayload_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateViewPayload_OneOfDesc> _UpdateViewPayload_OneOfDescByTag = {
    3 : UpdateViewPayload_OneOfDesc.desc,
    0 : UpdateViewPayload_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateViewPayload_OneOfThumbnail> _UpdateViewPayload_OneOfThumbnailByTag = {
    4 : UpdateViewPayload_OneOfThumbnail.thumbnail,
    0 : UpdateViewPayload_OneOfThumbnail.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateViewPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..hasRequiredFields = false
  ;

  UpdateViewPayload._() : super();
  factory UpdateViewPayload({
    $core.String? viewId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (thumbnail != null) {
      _result.thumbnail = thumbnail;
    }
    return _result;
  }
  factory UpdateViewPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateViewPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateViewPayload clone() => UpdateViewPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateViewPayload copyWith(void Function(UpdateViewPayload) updates) => super.copyWith((message) => updates(message as UpdateViewPayload)) as UpdateViewPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateViewPayload create() => UpdateViewPayload._();
  UpdateViewPayload createEmptyInstance() => create();
  static $pb.PbList<UpdateViewPayload> createRepeated() => $pb.PbList<UpdateViewPayload>();
  @$core.pragma('dart2js:noInline')
  static UpdateViewPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateViewPayload>(create);
  static UpdateViewPayload? _defaultInstance;

  UpdateViewPayload_OneOfName whichOneOfName() => _UpdateViewPayload_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateViewPayload_OneOfDesc whichOneOfDesc() => _UpdateViewPayload_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateViewPayload_OneOfThumbnail whichOneOfThumbnail() => _UpdateViewPayload_OneOfThumbnailByTag[$_whichOneof(2)]!;
  void clearOneOfThumbnail() => clearField($_whichOneof(2));

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

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
  $core.String get thumbnail => $_getSZ(3);
  @$pb.TagNumber(4)
  set thumbnail($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasThumbnail() => $_has(3);
  @$pb.TagNumber(4)
  void clearThumbnail() => clearField(4);
}

enum UpdateViewParams_OneOfName {
  name, 
  notSet
}

enum UpdateViewParams_OneOfDesc {
  desc, 
  notSet
}

enum UpdateViewParams_OneOfThumbnail {
  thumbnail, 
  notSet
}

class UpdateViewParams extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateViewParams_OneOfName> _UpdateViewParams_OneOfNameByTag = {
    2 : UpdateViewParams_OneOfName.name,
    0 : UpdateViewParams_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateViewParams_OneOfDesc> _UpdateViewParams_OneOfDescByTag = {
    3 : UpdateViewParams_OneOfDesc.desc,
    0 : UpdateViewParams_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateViewParams_OneOfThumbnail> _UpdateViewParams_OneOfThumbnailByTag = {
    4 : UpdateViewParams_OneOfThumbnail.thumbnail,
    0 : UpdateViewParams_OneOfThumbnail.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateViewParams', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..hasRequiredFields = false
  ;

  UpdateViewParams._() : super();
  factory UpdateViewParams({
    $core.String? viewId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (thumbnail != null) {
      _result.thumbnail = thumbnail;
    }
    return _result;
  }
  factory UpdateViewParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateViewParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateViewParams clone() => UpdateViewParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateViewParams copyWith(void Function(UpdateViewParams) updates) => super.copyWith((message) => updates(message as UpdateViewParams)) as UpdateViewParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateViewParams create() => UpdateViewParams._();
  UpdateViewParams createEmptyInstance() => create();
  static $pb.PbList<UpdateViewParams> createRepeated() => $pb.PbList<UpdateViewParams>();
  @$core.pragma('dart2js:noInline')
  static UpdateViewParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateViewParams>(create);
  static UpdateViewParams? _defaultInstance;

  UpdateViewParams_OneOfName whichOneOfName() => _UpdateViewParams_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateViewParams_OneOfDesc whichOneOfDesc() => _UpdateViewParams_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateViewParams_OneOfThumbnail whichOneOfThumbnail() => _UpdateViewParams_OneOfThumbnailByTag[$_whichOneof(2)]!;
  void clearOneOfThumbnail() => clearField($_whichOneof(2));

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

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
  $core.String get thumbnail => $_getSZ(3);
  @$pb.TagNumber(4)
  set thumbnail($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasThumbnail() => $_has(3);
  @$pb.TagNumber(4)
  void clearThumbnail() => clearField(4);
}

