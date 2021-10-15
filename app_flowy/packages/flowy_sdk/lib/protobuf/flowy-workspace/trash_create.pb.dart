///
//  Generated code. Do not modify.
//  source: trash_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'trash_create.pbenum.dart';

export 'trash_create.pbenum.dart';

class CreateTrashParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateTrashParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..e<TrashType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: TrashType.Unknown, valueOf: TrashType.valueOf, enumValues: TrashType.values)
    ..hasRequiredFields = false
  ;

  CreateTrashParams._() : super();
  factory CreateTrashParams({
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
  factory CreateTrashParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateTrashParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateTrashParams clone() => CreateTrashParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateTrashParams copyWith(void Function(CreateTrashParams) updates) => super.copyWith((message) => updates(message as CreateTrashParams)) as CreateTrashParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateTrashParams create() => CreateTrashParams._();
  CreateTrashParams createEmptyInstance() => create();
  static $pb.PbList<CreateTrashParams> createRepeated() => $pb.PbList<CreateTrashParams>();
  @$core.pragma('dart2js:noInline')
  static CreateTrashParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateTrashParams>(create);
  static CreateTrashParams? _defaultInstance;

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

class Trash extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Trash', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'modifiedTime')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime')
    ..e<TrashType>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: TrashType.Unknown, valueOf: TrashType.valueOf, enumValues: TrashType.values)
    ..hasRequiredFields = false
  ;

  Trash._() : super();
  factory Trash({
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
  factory Trash.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Trash.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Trash clone() => Trash()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Trash copyWith(void Function(Trash) updates) => super.copyWith((message) => updates(message as Trash)) as Trash; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Trash create() => Trash._();
  Trash createEmptyInstance() => create();
  static $pb.PbList<Trash> createRepeated() => $pb.PbList<Trash>();
  @$core.pragma('dart2js:noInline')
  static Trash getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Trash>(create);
  static Trash? _defaultInstance;

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

class RepeatedTrash extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepeatedTrash', createEmptyInstance: create)
    ..pc<Trash>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items', $pb.PbFieldType.PM, subBuilder: Trash.create)
    ..hasRequiredFields = false
  ;

  RepeatedTrash._() : super();
  factory RepeatedTrash({
    $core.Iterable<Trash>? items,
  }) {
    final _result = create();
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory RepeatedTrash.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepeatedTrash.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepeatedTrash clone() => RepeatedTrash()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepeatedTrash copyWith(void Function(RepeatedTrash) updates) => super.copyWith((message) => updates(message as RepeatedTrash)) as RepeatedTrash; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepeatedTrash create() => RepeatedTrash._();
  RepeatedTrash createEmptyInstance() => create();
  static $pb.PbList<RepeatedTrash> createRepeated() => $pb.PbList<RepeatedTrash>();
  @$core.pragma('dart2js:noInline')
  static RepeatedTrash getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepeatedTrash>(create);
  static RepeatedTrash? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Trash> get items => $_getList(0);
}

