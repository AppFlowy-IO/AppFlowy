///
//  Generated code. Do not modify.
//  source: revision.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'revision.pbenum.dart';

export 'revision.pbenum.dart';

class RevId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RevId', createEmptyInstance: create)
    ..aInt64(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  RevId._() : super();
  factory RevId({
    $fixnum.Int64? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory RevId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RevId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RevId clone() => RevId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RevId copyWith(void Function(RevId) updates) => super.copyWith((message) => updates(message as RevId)) as RevId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RevId create() => RevId._();
  RevId createEmptyInstance() => create();
  static $pb.PbList<RevId> createRepeated() => $pb.PbList<RevId>();
  @$core.pragma('dart2js:noInline')
  static RevId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RevId>(create);
  static RevId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get value => $_getI64(0);
  @$pb.TagNumber(1)
  set value($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

class Revision extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Revision', createEmptyInstance: create)
    ..aInt64(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'baseRevId')
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deltaData', $pb.PbFieldType.OY)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'md5')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..e<RevType>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: RevType.Local, valueOf: RevType.valueOf, enumValues: RevType.values)
    ..hasRequiredFields = false
  ;

  Revision._() : super();
  factory Revision({
    $fixnum.Int64? baseRevId,
    $fixnum.Int64? revId,
    $core.List<$core.int>? deltaData,
    $core.String? md5,
    $core.String? docId,
    RevType? ty,
  }) {
    final _result = create();
    if (baseRevId != null) {
      _result.baseRevId = baseRevId;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    if (deltaData != null) {
      _result.deltaData = deltaData;
    }
    if (md5 != null) {
      _result.md5 = md5;
    }
    if (docId != null) {
      _result.docId = docId;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    return _result;
  }
  factory Revision.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Revision.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Revision clone() => Revision()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Revision copyWith(void Function(Revision) updates) => super.copyWith((message) => updates(message as Revision)) as Revision; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Revision create() => Revision._();
  Revision createEmptyInstance() => create();
  static $pb.PbList<Revision> createRepeated() => $pb.PbList<Revision>();
  @$core.pragma('dart2js:noInline')
  static Revision getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Revision>(create);
  static Revision? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get baseRevId => $_getI64(0);
  @$pb.TagNumber(1)
  set baseRevId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBaseRevId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBaseRevId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revId => $_getI64(1);
  @$pb.TagNumber(2)
  set revId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRevId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get deltaData => $_getN(2);
  @$pb.TagNumber(3)
  set deltaData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDeltaData() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeltaData() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get md5 => $_getSZ(3);
  @$pb.TagNumber(4)
  set md5($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMd5() => $_has(3);
  @$pb.TagNumber(4)
  void clearMd5() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get docId => $_getSZ(4);
  @$pb.TagNumber(5)
  set docId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDocId() => $_has(4);
  @$pb.TagNumber(5)
  void clearDocId() => clearField(5);

  @$pb.TagNumber(6)
  RevType get ty => $_getN(5);
  @$pb.TagNumber(6)
  set ty(RevType v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasTy() => $_has(5);
  @$pb.TagNumber(6)
  void clearTy() => clearField(6);
}

class RevisionRange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RevisionRange', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromRevId')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'toRevId')
    ..hasRequiredFields = false
  ;

  RevisionRange._() : super();
  factory RevisionRange({
    $core.String? docId,
    $fixnum.Int64? fromRevId,
    $fixnum.Int64? toRevId,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (fromRevId != null) {
      _result.fromRevId = fromRevId;
    }
    if (toRevId != null) {
      _result.toRevId = toRevId;
    }
    return _result;
  }
  factory RevisionRange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RevisionRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RevisionRange clone() => RevisionRange()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RevisionRange copyWith(void Function(RevisionRange) updates) => super.copyWith((message) => updates(message as RevisionRange)) as RevisionRange; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RevisionRange create() => RevisionRange._();
  RevisionRange createEmptyInstance() => create();
  static $pb.PbList<RevisionRange> createRepeated() => $pb.PbList<RevisionRange>();
  @$core.pragma('dart2js:noInline')
  static RevisionRange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RevisionRange>(create);
  static RevisionRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fromRevId => $_getI64(1);
  @$pb.TagNumber(2)
  set fromRevId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFromRevId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromRevId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get toRevId => $_getI64(2);
  @$pb.TagNumber(3)
  set toRevId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasToRevId() => $_has(2);
  @$pb.TagNumber(3)
  void clearToRevId() => clearField(3);
}

