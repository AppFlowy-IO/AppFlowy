///
//  Generated code. Do not modify.
//  source: view_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'view_create.pbenum.dart';

export 'view_create.pbenum.dart';

enum CreateViewRequest_OneOfThumbnail {
  thumbnail, 
  notSet
}

class CreateViewRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateViewRequest_OneOfThumbnail> _CreateViewRequest_OneOfThumbnailByTag = {
    4 : CreateViewRequest_OneOfThumbnail.thumbnail,
    0 : CreateViewRequest_OneOfThumbnail.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateViewRequest', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..e<ViewType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewType', $pb.PbFieldType.OE, defaultOrMaker: ViewType.Blank, valueOf: ViewType.valueOf, enumValues: ViewType.values)
    ..hasRequiredFields = false
  ;

  CreateViewRequest._() : super();
  factory CreateViewRequest({
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    ViewType? viewType,
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
    if (viewType != null) {
      _result.viewType = viewType;
    }
    return _result;
  }
  factory CreateViewRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateViewRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateViewRequest clone() => CreateViewRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateViewRequest copyWith(void Function(CreateViewRequest) updates) => super.copyWith((message) => updates(message as CreateViewRequest)) as CreateViewRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateViewRequest create() => CreateViewRequest._();
  CreateViewRequest createEmptyInstance() => create();
  static $pb.PbList<CreateViewRequest> createRepeated() => $pb.PbList<CreateViewRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateViewRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateViewRequest>(create);
  static CreateViewRequest? _defaultInstance;

  CreateViewRequest_OneOfThumbnail whichOneOfThumbnail() => _CreateViewRequest_OneOfThumbnailByTag[$_whichOneof(0)]!;
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
  ViewType get viewType => $_getN(4);
  @$pb.TagNumber(5)
  set viewType(ViewType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasViewType() => $_has(4);
  @$pb.TagNumber(5)
  void clearViewType() => clearField(5);
}

class CreateViewParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateViewParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..e<ViewType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewType', $pb.PbFieldType.OE, defaultOrMaker: ViewType.Blank, valueOf: ViewType.valueOf, enumValues: ViewType.values)
    ..hasRequiredFields = false
  ;

  CreateViewParams._() : super();
  factory CreateViewParams({
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    ViewType? viewType,
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
    if (viewType != null) {
      _result.viewType = viewType;
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
  ViewType get viewType => $_getN(4);
  @$pb.TagNumber(5)
  set viewType(ViewType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasViewType() => $_has(4);
  @$pb.TagNumber(5)
  void clearViewType() => clearField(5);
}

class View extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'View', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<ViewType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewType', $pb.PbFieldType.OE, defaultOrMaker: ViewType.Blank, valueOf: ViewType.valueOf, enumValues: ViewType.values)
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..aOM<RepeatedView>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongings', subBuilder: RepeatedView.create)
    ..aInt64(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..hasRequiredFields = false
  ;

  View._() : super();
  factory View({
    $core.String? id,
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    ViewType? viewType,
    $fixnum.Int64? version,
    RepeatedView? belongings,
    $fixnum.Int64? modifiedTime,
    $fixnum.Int64? createTime,
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
    if (viewType != null) {
      _result.viewType = viewType;
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
  ViewType get viewType => $_getN(4);
  @$pb.TagNumber(5)
  set viewType(ViewType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasViewType() => $_has(4);
  @$pb.TagNumber(5)
  void clearViewType() => clearField(5);

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

