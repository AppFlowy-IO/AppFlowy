///
//  Generated code. Do not modify.
//  source: view.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'view.pbenum.dart';

export 'view.pbenum.dart';

class ViewPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..e<ViewDataFormatPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataFormat', $pb.PbFieldType.OE, defaultOrMaker: ViewDataFormatPB.DeltaFormat, valueOf: ViewDataFormatPB.valueOf, enumValues: ViewDataFormatPB.values)
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..e<ViewLayoutTypePB>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'layout', $pb.PbFieldType.OE, defaultOrMaker: ViewLayoutTypePB.Document, valueOf: ViewLayoutTypePB.valueOf, enumValues: ViewLayoutTypePB.values)
    ..hasRequiredFields = false
  ;

  ViewPB._() : super();
  factory ViewPB({
    $core.String? id,
    $core.String? appId,
    $core.String? name,
    ViewDataFormatPB? dataFormat,
    $fixnum.Int64? modifiedTime,
    $fixnum.Int64? createTime,
    ViewLayoutTypePB? layout,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (appId != null) {
      _result.appId = appId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (dataFormat != null) {
      _result.dataFormat = dataFormat;
    }
    if (modifiedTime != null) {
      _result.modifiedTime = modifiedTime;
    }
    if (createTime != null) {
      _result.createTime = createTime;
    }
    if (layout != null) {
      _result.layout = layout;
    }
    return _result;
  }
  factory ViewPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewPB clone() => ViewPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewPB copyWith(void Function(ViewPB) updates) => super.copyWith((message) => updates(message as ViewPB)) as ViewPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewPB create() => ViewPB._();
  ViewPB createEmptyInstance() => create();
  static $pb.PbList<ViewPB> createRepeated() => $pb.PbList<ViewPB>();
  @$core.pragma('dart2js:noInline')
  static ViewPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewPB>(create);
  static ViewPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get appId => $_getSZ(1);
  @$pb.TagNumber(2)
  set appId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAppId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  ViewDataFormatPB get dataFormat => $_getN(3);
  @$pb.TagNumber(4)
  set dataFormat(ViewDataFormatPB v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasDataFormat() => $_has(3);
  @$pb.TagNumber(4)
  void clearDataFormat() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get modifiedTime => $_getI64(4);
  @$pb.TagNumber(5)
  set modifiedTime($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasModifiedTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearModifiedTime() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get createTime => $_getI64(5);
  @$pb.TagNumber(6)
  set createTime($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasCreateTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreateTime() => clearField(6);

  @$pb.TagNumber(7)
  ViewLayoutTypePB get layout => $_getN(6);
  @$pb.TagNumber(7)
  set layout(ViewLayoutTypePB v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasLayout() => $_has(6);
  @$pb.TagNumber(7)
  void clearLayout() => clearField(7);
}

class RepeatedViewPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedViewPB', createEmptyInstance: create)
    ..pc<ViewPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: ViewPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedViewPB._() : super();
  factory RepeatedViewPB({
    $core.Iterable<ViewPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedViewPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedViewPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedViewPB clone() => RepeatedViewPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedViewPB copyWith(void Function(RepeatedViewPB) updates) => super.copyWith((message) => updates(message as RepeatedViewPB)) as RepeatedViewPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedViewPB create() => RepeatedViewPB._();
  RepeatedViewPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedViewPB> createRepeated() => $pb.PbList<RepeatedViewPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedViewPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedViewPB>(create);
  static RepeatedViewPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ViewPB> get items => $_getList(0);
}

class RepeatedViewIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedViewIdPB', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items')
    ..hasRequiredFields = false
  ;

  RepeatedViewIdPB._() : super();
  factory RepeatedViewIdPB({
    $core.Iterable<$core.String>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedViewIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedViewIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedViewIdPB clone() => RepeatedViewIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedViewIdPB copyWith(void Function(RepeatedViewIdPB) updates) => super.copyWith((message) => updates(message as RepeatedViewIdPB)) as RepeatedViewIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedViewIdPB create() => RepeatedViewIdPB._();
  RepeatedViewIdPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedViewIdPB> createRepeated() => $pb.PbList<RepeatedViewIdPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedViewIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedViewIdPB>(create);
  static RepeatedViewIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get items => $_getList(0);
}

enum CreateViewPayloadPB_OneOfThumbnail {
  thumbnail, 
  notSet
}

class CreateViewPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateViewPayloadPB_OneOfThumbnail> _CreateViewPayloadPB_OneOfThumbnailByTag = {
    4 : CreateViewPayloadPB_OneOfThumbnail.thumbnail,
    0 : CreateViewPayloadPB_OneOfThumbnail.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateViewPayloadPB', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..e<ViewDataFormatPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataFormat', $pb.PbFieldType.OE, defaultOrMaker: ViewDataFormatPB.DeltaFormat, valueOf: ViewDataFormatPB.valueOf, enumValues: ViewDataFormatPB.values)
    ..e<ViewLayoutTypePB>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'layout', $pb.PbFieldType.OE, defaultOrMaker: ViewLayoutTypePB.Document, valueOf: ViewLayoutTypePB.valueOf, enumValues: ViewLayoutTypePB.values)
    ..a<$core.List<$core.int>>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewContentData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  CreateViewPayloadPB._() : super();
  factory CreateViewPayloadPB({
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    ViewDataFormatPB? dataFormat,
    ViewLayoutTypePB? layout,
    $core.List<$core.int>? viewContentData,
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
    if (dataFormat != null) {
      _result.dataFormat = dataFormat;
    }
    if (layout != null) {
      _result.layout = layout;
    }
    if (viewContentData != null) {
      _result.viewContentData = viewContentData;
    }
    return _result;
  }
  factory CreateViewPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateViewPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateViewPayloadPB clone() => CreateViewPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateViewPayloadPB copyWith(void Function(CreateViewPayloadPB) updates) => super.copyWith((message) => updates(message as CreateViewPayloadPB)) as CreateViewPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateViewPayloadPB create() => CreateViewPayloadPB._();
  CreateViewPayloadPB createEmptyInstance() => create();
  static $pb.PbList<CreateViewPayloadPB> createRepeated() => $pb.PbList<CreateViewPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static CreateViewPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateViewPayloadPB>(create);
  static CreateViewPayloadPB? _defaultInstance;

  CreateViewPayloadPB_OneOfThumbnail whichOneOfThumbnail() => _CreateViewPayloadPB_OneOfThumbnailByTag[$_whichOneof(0)]!;
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
  ViewDataFormatPB get dataFormat => $_getN(4);
  @$pb.TagNumber(5)
  set dataFormat(ViewDataFormatPB v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDataFormat() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataFormat() => clearField(5);

  @$pb.TagNumber(6)
  ViewLayoutTypePB get layout => $_getN(5);
  @$pb.TagNumber(6)
  set layout(ViewLayoutTypePB v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasLayout() => $_has(5);
  @$pb.TagNumber(6)
  void clearLayout() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get viewContentData => $_getN(6);
  @$pb.TagNumber(7)
  set viewContentData($core.List<$core.int> v) { $_setBytes(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasViewContentData() => $_has(6);
  @$pb.TagNumber(7)
  void clearViewContentData() => clearField(7);
}

class ViewIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewIdPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  ViewIdPB._() : super();
  factory ViewIdPB({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory ViewIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewIdPB clone() => ViewIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewIdPB copyWith(void Function(ViewIdPB) updates) => super.copyWith((message) => updates(message as ViewIdPB)) as ViewIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewIdPB create() => ViewIdPB._();
  ViewIdPB createEmptyInstance() => create();
  static $pb.PbList<ViewIdPB> createRepeated() => $pb.PbList<ViewIdPB>();
  @$core.pragma('dart2js:noInline')
  static ViewIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewIdPB>(create);
  static ViewIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

enum DeletedViewPB_OneOfIndex {
  index_, 
  notSet
}

class DeletedViewPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, DeletedViewPB_OneOfIndex> _DeletedViewPB_OneOfIndexByTag = {
    2 : DeletedViewPB_OneOfIndex.index_,
    0 : DeletedViewPB_OneOfIndex.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DeletedViewPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'index', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  DeletedViewPB._() : super();
  factory DeletedViewPB({
    $core.String? viewId,
    $core.int? index,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (index != null) {
      _result.index = index;
    }
    return _result;
  }
  factory DeletedViewPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeletedViewPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeletedViewPB clone() => DeletedViewPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeletedViewPB copyWith(void Function(DeletedViewPB) updates) => super.copyWith((message) => updates(message as DeletedViewPB)) as DeletedViewPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeletedViewPB create() => DeletedViewPB._();
  DeletedViewPB createEmptyInstance() => create();
  static $pb.PbList<DeletedViewPB> createRepeated() => $pb.PbList<DeletedViewPB>();
  @$core.pragma('dart2js:noInline')
  static DeletedViewPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeletedViewPB>(create);
  static DeletedViewPB? _defaultInstance;

  DeletedViewPB_OneOfIndex whichOneOfIndex() => _DeletedViewPB_OneOfIndexByTag[$_whichOneof(0)]!;
  void clearOneOfIndex() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);
}

enum UpdateViewPayloadPB_OneOfName {
  name, 
  notSet
}

enum UpdateViewPayloadPB_OneOfDesc {
  desc, 
  notSet
}

enum UpdateViewPayloadPB_OneOfThumbnail {
  thumbnail, 
  notSet
}

class UpdateViewPayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateViewPayloadPB_OneOfName> _UpdateViewPayloadPB_OneOfNameByTag = {
    2 : UpdateViewPayloadPB_OneOfName.name,
    0 : UpdateViewPayloadPB_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateViewPayloadPB_OneOfDesc> _UpdateViewPayloadPB_OneOfDescByTag = {
    3 : UpdateViewPayloadPB_OneOfDesc.desc,
    0 : UpdateViewPayloadPB_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateViewPayloadPB_OneOfThumbnail> _UpdateViewPayloadPB_OneOfThumbnailByTag = {
    4 : UpdateViewPayloadPB_OneOfThumbnail.thumbnail,
    0 : UpdateViewPayloadPB_OneOfThumbnail.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateViewPayloadPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..hasRequiredFields = false
  ;

  UpdateViewPayloadPB._() : super();
  factory UpdateViewPayloadPB({
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
  factory UpdateViewPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateViewPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateViewPayloadPB clone() => UpdateViewPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateViewPayloadPB copyWith(void Function(UpdateViewPayloadPB) updates) => super.copyWith((message) => updates(message as UpdateViewPayloadPB)) as UpdateViewPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateViewPayloadPB create() => UpdateViewPayloadPB._();
  UpdateViewPayloadPB createEmptyInstance() => create();
  static $pb.PbList<UpdateViewPayloadPB> createRepeated() => $pb.PbList<UpdateViewPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static UpdateViewPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateViewPayloadPB>(create);
  static UpdateViewPayloadPB? _defaultInstance;

  UpdateViewPayloadPB_OneOfName whichOneOfName() => _UpdateViewPayloadPB_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateViewPayloadPB_OneOfDesc whichOneOfDesc() => _UpdateViewPayloadPB_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateViewPayloadPB_OneOfThumbnail whichOneOfThumbnail() => _UpdateViewPayloadPB_OneOfThumbnailByTag[$_whichOneof(2)]!;
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

class MoveFolderItemPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MoveFolderItemPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'itemId')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'from', $pb.PbFieldType.O3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'to', $pb.PbFieldType.O3)
    ..e<MoveFolderItemType>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: MoveFolderItemType.MoveApp, valueOf: MoveFolderItemType.valueOf, enumValues: MoveFolderItemType.values)
    ..hasRequiredFields = false
  ;

  MoveFolderItemPayloadPB._() : super();
  factory MoveFolderItemPayloadPB({
    $core.String? itemId,
    $core.int? from,
    $core.int? to,
    MoveFolderItemType? ty,
  }) {
    final _result = create();
    if (itemId != null) {
      _result.itemId = itemId;
    }
    if (from != null) {
      _result.from = from;
    }
    if (to != null) {
      _result.to = to;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    return _result;
  }
  factory MoveFolderItemPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MoveFolderItemPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MoveFolderItemPayloadPB clone() => MoveFolderItemPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MoveFolderItemPayloadPB copyWith(void Function(MoveFolderItemPayloadPB) updates) => super.copyWith((message) => updates(message as MoveFolderItemPayloadPB)) as MoveFolderItemPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MoveFolderItemPayloadPB create() => MoveFolderItemPayloadPB._();
  MoveFolderItemPayloadPB createEmptyInstance() => create();
  static $pb.PbList<MoveFolderItemPayloadPB> createRepeated() => $pb.PbList<MoveFolderItemPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static MoveFolderItemPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MoveFolderItemPayloadPB>(create);
  static MoveFolderItemPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get itemId => $_getSZ(0);
  @$pb.TagNumber(1)
  set itemId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasItemId() => $_has(0);
  @$pb.TagNumber(1)
  void clearItemId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get from => $_getIZ(1);
  @$pb.TagNumber(2)
  set from($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFrom() => $_has(1);
  @$pb.TagNumber(2)
  void clearFrom() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get to => $_getIZ(2);
  @$pb.TagNumber(3)
  set to($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTo() => $_has(2);
  @$pb.TagNumber(3)
  void clearTo() => clearField(3);

  @$pb.TagNumber(4)
  MoveFolderItemType get ty => $_getN(3);
  @$pb.TagNumber(4)
  set ty(MoveFolderItemType v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasTy() => $_has(3);
  @$pb.TagNumber(4)
  void clearTy() => clearField(4);
}

