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
    ..e<ViewDataType>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', $pb.PbFieldType.OE, defaultOrMaker: ViewDataType.TextBlock, valueOf: ViewDataType.valueOf, enumValues: ViewDataType.values)
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..a<$core.int>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pluginType', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  View._() : super();
  factory View({
    $core.String? id,
    $core.String? belongToId,
    $core.String? name,
    ViewDataType? dataType,
    $fixnum.Int64? modifiedTime,
    $fixnum.Int64? createTime,
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
    if (dataType != null) {
      _result.dataType = dataType;
    }
    if (modifiedTime != null) {
      _result.modifiedTime = modifiedTime;
    }
    if (createTime != null) {
      _result.createTime = createTime;
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
  ViewDataType get dataType => $_getN(3);
  @$pb.TagNumber(4)
  set dataType(ViewDataType v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasDataType() => $_has(3);
  @$pb.TagNumber(4)
  void clearDataType() => clearField(4);

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
  $core.int get pluginType => $_getIZ(6);
  @$pb.TagNumber(7)
  set pluginType($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasPluginType() => $_has(6);
  @$pb.TagNumber(7)
  void clearPluginType() => clearField(7);
}

class ViewInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewInfo', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<ViewDataType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', $pb.PbFieldType.OE, defaultOrMaker: ViewDataType.TextBlock, valueOf: ViewDataType.valueOf, enumValues: ViewDataType.values)
    ..aOM<RepeatedView>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongings', subBuilder: RepeatedView.create)
    ..aOM<ViewExtData>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extData', subBuilder: ViewExtData.create)
    ..hasRequiredFields = false
  ;

  ViewInfo._() : super();
  factory ViewInfo({
    $core.String? id,
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    ViewDataType? dataType,
    RepeatedView? belongings,
    ViewExtData? extData,
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
    if (belongings != null) {
      _result.belongings = belongings;
    }
    if (extData != null) {
      _result.extData = extData;
    }
    return _result;
  }
  factory ViewInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewInfo clone() => ViewInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewInfo copyWith(void Function(ViewInfo) updates) => super.copyWith((message) => updates(message as ViewInfo)) as ViewInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewInfo create() => ViewInfo._();
  ViewInfo createEmptyInstance() => create();
  static $pb.PbList<ViewInfo> createRepeated() => $pb.PbList<ViewInfo>();
  @$core.pragma('dart2js:noInline')
  static ViewInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewInfo>(create);
  static ViewInfo? _defaultInstance;

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
  RepeatedView get belongings => $_getN(5);
  @$pb.TagNumber(6)
  set belongings(RepeatedView v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasBelongings() => $_has(5);
  @$pb.TagNumber(6)
  void clearBelongings() => clearField(6);
  @$pb.TagNumber(6)
  RepeatedView ensureBelongings() => $_ensure(5);

  @$pb.TagNumber(7)
  ViewExtData get extData => $_getN(6);
  @$pb.TagNumber(7)
  set extData(ViewExtData v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasExtData() => $_has(6);
  @$pb.TagNumber(7)
  void clearExtData() => clearField(7);
  @$pb.TagNumber(7)
  ViewExtData ensureExtData() => $_ensure(6);
}

class ViewExtData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewExtData', createEmptyInstance: create)
    ..aOM<ViewFilter>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'filter', subBuilder: ViewFilter.create)
    ..aOM<ViewGroup>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'group', subBuilder: ViewGroup.create)
    ..aOM<ViewSort>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sort', subBuilder: ViewSort.create)
    ..hasRequiredFields = false
  ;

  ViewExtData._() : super();
  factory ViewExtData({
    ViewFilter? filter,
    ViewGroup? group,
    ViewSort? sort,
  }) {
    final _result = create();
    if (filter != null) {
      _result.filter = filter;
    }
    if (group != null) {
      _result.group = group;
    }
    if (sort != null) {
      _result.sort = sort;
    }
    return _result;
  }
  factory ViewExtData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewExtData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewExtData clone() => ViewExtData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewExtData copyWith(void Function(ViewExtData) updates) => super.copyWith((message) => updates(message as ViewExtData)) as ViewExtData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewExtData create() => ViewExtData._();
  ViewExtData createEmptyInstance() => create();
  static $pb.PbList<ViewExtData> createRepeated() => $pb.PbList<ViewExtData>();
  @$core.pragma('dart2js:noInline')
  static ViewExtData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewExtData>(create);
  static ViewExtData? _defaultInstance;

  @$pb.TagNumber(1)
  ViewFilter get filter => $_getN(0);
  @$pb.TagNumber(1)
  set filter(ViewFilter v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFilter() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilter() => clearField(1);
  @$pb.TagNumber(1)
  ViewFilter ensureFilter() => $_ensure(0);

  @$pb.TagNumber(2)
  ViewGroup get group => $_getN(1);
  @$pb.TagNumber(2)
  set group(ViewGroup v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroup() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroup() => clearField(2);
  @$pb.TagNumber(2)
  ViewGroup ensureGroup() => $_ensure(1);

  @$pb.TagNumber(3)
  ViewSort get sort => $_getN(2);
  @$pb.TagNumber(3)
  set sort(ViewSort v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSort() => $_has(2);
  @$pb.TagNumber(3)
  void clearSort() => clearField(3);
  @$pb.TagNumber(3)
  ViewSort ensureSort() => $_ensure(2);
}

class ViewFilter extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewFilter', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..hasRequiredFields = false
  ;

  ViewFilter._() : super();
  factory ViewFilter({
    $core.String? fieldId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    return _result;
  }
  factory ViewFilter.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewFilter.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewFilter clone() => ViewFilter()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewFilter copyWith(void Function(ViewFilter) updates) => super.copyWith((message) => updates(message as ViewFilter)) as ViewFilter; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewFilter create() => ViewFilter._();
  ViewFilter createEmptyInstance() => create();
  static $pb.PbList<ViewFilter> createRepeated() => $pb.PbList<ViewFilter>();
  @$core.pragma('dart2js:noInline')
  static ViewFilter getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewFilter>(create);
  static ViewFilter? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);
}

enum ViewGroup_OneOfSubGroupFieldId {
  subGroupFieldId, 
  notSet
}

class ViewGroup extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ViewGroup_OneOfSubGroupFieldId> _ViewGroup_OneOfSubGroupFieldIdByTag = {
    2 : ViewGroup_OneOfSubGroupFieldId.subGroupFieldId,
    0 : ViewGroup_OneOfSubGroupFieldId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewGroup', createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupFieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'subGroupFieldId')
    ..hasRequiredFields = false
  ;

  ViewGroup._() : super();
  factory ViewGroup({
    $core.String? groupFieldId,
    $core.String? subGroupFieldId,
  }) {
    final _result = create();
    if (groupFieldId != null) {
      _result.groupFieldId = groupFieldId;
    }
    if (subGroupFieldId != null) {
      _result.subGroupFieldId = subGroupFieldId;
    }
    return _result;
  }
  factory ViewGroup.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewGroup.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewGroup clone() => ViewGroup()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewGroup copyWith(void Function(ViewGroup) updates) => super.copyWith((message) => updates(message as ViewGroup)) as ViewGroup; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewGroup create() => ViewGroup._();
  ViewGroup createEmptyInstance() => create();
  static $pb.PbList<ViewGroup> createRepeated() => $pb.PbList<ViewGroup>();
  @$core.pragma('dart2js:noInline')
  static ViewGroup getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewGroup>(create);
  static ViewGroup? _defaultInstance;

  ViewGroup_OneOfSubGroupFieldId whichOneOfSubGroupFieldId() => _ViewGroup_OneOfSubGroupFieldIdByTag[$_whichOneof(0)]!;
  void clearOneOfSubGroupFieldId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get groupFieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupFieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get subGroupFieldId => $_getSZ(1);
  @$pb.TagNumber(2)
  set subGroupFieldId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSubGroupFieldId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubGroupFieldId() => clearField(2);
}

class ViewSort extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewSort', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..hasRequiredFields = false
  ;

  ViewSort._() : super();
  factory ViewSort({
    $core.String? fieldId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    return _result;
  }
  factory ViewSort.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewSort.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewSort clone() => ViewSort()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewSort copyWith(void Function(ViewSort) updates) => super.copyWith((message) => updates(message as ViewSort)) as ViewSort; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewSort create() => ViewSort._();
  ViewSort createEmptyInstance() => create();
  static $pb.PbList<ViewSort> createRepeated() => $pb.PbList<ViewSort>();
  @$core.pragma('dart2js:noInline')
  static ViewSort getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewSort>(create);
  static ViewSort? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);
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
    ..a<$core.int>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pluginType', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  CreateViewPayload._() : super();
  factory CreateViewPayload({
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    ViewDataType? dataType,
    $core.int? pluginType,
    $core.List<$core.int>? data,
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
    if (pluginType != null) {
      _result.pluginType = pluginType;
    }
    if (data != null) {
      _result.data = data;
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
  $core.int get pluginType => $_getIZ(5);
  @$pb.TagNumber(6)
  set pluginType($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPluginType() => $_has(5);
  @$pb.TagNumber(6)
  void clearPluginType() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get data => $_getN(6);
  @$pb.TagNumber(7)
  set data($core.List<$core.int> v) { $_setBytes(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasData() => $_has(6);
  @$pb.TagNumber(7)
  void clearData() => clearField(7);
}

class CreateViewParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateViewParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..e<ViewDataType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', $pb.PbFieldType.OE, defaultOrMaker: ViewDataType.TextBlock, valueOf: ViewDataType.valueOf, enumValues: ViewDataType.values)
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..a<$core.List<$core.int>>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..a<$core.int>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pluginType', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  CreateViewParams._() : super();
  factory CreateViewParams({
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    ViewDataType? dataType,
    $core.String? viewId,
    $core.List<$core.int>? data,
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
  $core.String get viewId => $_getSZ(5);
  @$pb.TagNumber(6)
  set viewId($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasViewId() => $_has(5);
  @$pb.TagNumber(6)
  void clearViewId() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get data => $_getN(6);
  @$pb.TagNumber(7)
  set data($core.List<$core.int> v) { $_setBytes(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasData() => $_has(6);
  @$pb.TagNumber(7)
  void clearData() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get pluginType => $_getIZ(7);
  @$pb.TagNumber(8)
  set pluginType($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasPluginType() => $_has(7);
  @$pb.TagNumber(8)
  void clearPluginType() => clearField(8);
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

class MoveFolderItemPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MoveFolderItemPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'itemId')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'from', $pb.PbFieldType.O3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'to', $pb.PbFieldType.O3)
    ..e<MoveFolderItemType>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: MoveFolderItemType.MoveApp, valueOf: MoveFolderItemType.valueOf, enumValues: MoveFolderItemType.values)
    ..hasRequiredFields = false
  ;

  MoveFolderItemPayload._() : super();
  factory MoveFolderItemPayload({
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
  factory MoveFolderItemPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MoveFolderItemPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MoveFolderItemPayload clone() => MoveFolderItemPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MoveFolderItemPayload copyWith(void Function(MoveFolderItemPayload) updates) => super.copyWith((message) => updates(message as MoveFolderItemPayload)) as MoveFolderItemPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MoveFolderItemPayload create() => MoveFolderItemPayload._();
  MoveFolderItemPayload createEmptyInstance() => create();
  static $pb.PbList<MoveFolderItemPayload> createRepeated() => $pb.PbList<MoveFolderItemPayload>();
  @$core.pragma('dart2js:noInline')
  static MoveFolderItemPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MoveFolderItemPayload>(create);
  static MoveFolderItemPayload? _defaultInstance;

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

