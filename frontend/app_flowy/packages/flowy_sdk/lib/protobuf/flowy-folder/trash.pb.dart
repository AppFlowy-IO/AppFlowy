///
//  Generated code. Do not modify.
//  source: trash.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'trash.pbenum.dart';

export 'trash.pbenum.dart';

class TrashPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TrashPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..e<TrashType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: TrashType.TrashUnknown, valueOf: TrashType.valueOf, enumValues: TrashType.values)
    ..hasRequiredFields = false
  ;

  TrashPB._() : super();
  factory TrashPB({
    $core.String? id,
    $core.String? name,
    $fixnum.Int64? modifiedTime,
    $fixnum.Int64? createTime,
    TrashType? ty,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (modifiedTime != null) {
      _result.modifiedTime = modifiedTime;
    }
    if (createTime != null) {
      _result.createTime = createTime;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    return _result;
  }
  factory TrashPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TrashPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TrashPB clone() => TrashPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TrashPB copyWith(void Function(TrashPB) updates) => super.copyWith((message) => updates(message as TrashPB)) as TrashPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrashPB create() => TrashPB._();
  TrashPB createEmptyInstance() => create();
  static $pb.PbList<TrashPB> createRepeated() => $pb.PbList<TrashPB>();
  @$core.pragma('dart2js:noInline')
  static TrashPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrashPB>(create);
  static TrashPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get modifiedTime => $_getI64(2);
  @$pb.TagNumber(3)
  set modifiedTime($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasModifiedTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearModifiedTime() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get createTime => $_getI64(3);
  @$pb.TagNumber(4)
  set createTime($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreateTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreateTime() => clearField(4);

  @$pb.TagNumber(5)
  TrashType get ty => $_getN(4);
  @$pb.TagNumber(5)
  set ty(TrashType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasTy() => $_has(4);
  @$pb.TagNumber(5)
  void clearTy() => clearField(5);
}

class RepeatedTrashPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedTrashPB', createEmptyInstance: create)
    ..pc<TrashPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: TrashPB.create)
    ..hasRequiredFields = false
  ;

  RepeatedTrashPB._() : super();
  factory RepeatedTrashPB({
    $core.Iterable<TrashPB>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedTrashPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedTrashPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedTrashPB clone() => RepeatedTrashPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedTrashPB copyWith(void Function(RepeatedTrashPB) updates) => super.copyWith((message) => updates(message as RepeatedTrashPB)) as RepeatedTrashPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedTrashPB create() => RepeatedTrashPB._();
  RepeatedTrashPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedTrashPB> createRepeated() => $pb.PbList<RepeatedTrashPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedTrashPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedTrashPB>(create);
  static RepeatedTrashPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<TrashPB> get items => $_getList(0);
}

class RepeatedTrashIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedTrashIdPB', createEmptyInstance: create)
    ..pc<TrashIdPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: TrashIdPB.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteAll')
    ..hasRequiredFields = false
  ;

  RepeatedTrashIdPB._() : super();
  factory RepeatedTrashIdPB({
    $core.Iterable<TrashIdPB>? items,
    $core.bool? deleteAll,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    if (deleteAll != null) {
      _result.deleteAll = deleteAll;
    }
    return _result;
  }
  factory RepeatedTrashIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedTrashIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedTrashIdPB clone() => RepeatedTrashIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedTrashIdPB copyWith(void Function(RepeatedTrashIdPB) updates) => super.copyWith((message) => updates(message as RepeatedTrashIdPB)) as RepeatedTrashIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedTrashIdPB create() => RepeatedTrashIdPB._();
  RepeatedTrashIdPB createEmptyInstance() => create();
  static $pb.PbList<RepeatedTrashIdPB> createRepeated() => $pb.PbList<RepeatedTrashIdPB>();
  @$core.pragma('dart2js:noInline')
  static RepeatedTrashIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedTrashIdPB>(create);
  static RepeatedTrashIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<TrashIdPB> get items => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get deleteAll => $_getBF(1);
  @$pb.TagNumber(2)
  set deleteAll($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeleteAll() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeleteAll() => clearField(2);
}

class TrashIdPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TrashIdPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..e<TrashType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: TrashType.TrashUnknown, valueOf: TrashType.valueOf, enumValues: TrashType.values)
    ..hasRequiredFields = false
  ;

  TrashIdPB._() : super();
  factory TrashIdPB({
    $core.String? id,
    TrashType? ty,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    return _result;
  }
  factory TrashIdPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TrashIdPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TrashIdPB clone() => TrashIdPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TrashIdPB copyWith(void Function(TrashIdPB) updates) => super.copyWith((message) => updates(message as TrashIdPB)) as TrashIdPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrashIdPB create() => TrashIdPB._();
  TrashIdPB createEmptyInstance() => create();
  static $pb.PbList<TrashIdPB> createRepeated() => $pb.PbList<TrashIdPB>();
  @$core.pragma('dart2js:noInline')
  static TrashIdPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrashIdPB>(create);
  static TrashIdPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  TrashType get ty => $_getN(1);
  @$pb.TagNumber(2)
  set ty(TrashType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTy() => $_has(1);
  @$pb.TagNumber(2)
  void clearTy() => clearField(2);
}

