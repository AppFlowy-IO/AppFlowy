///
//  Generated code. Do not modify.
//  source: document_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'revision.pb.dart' as $0;

class CreateBlockParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateBlockParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOM<$0.RepeatedRevision>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revisions', subBuilder: $0.RepeatedRevision.create)
    ..hasRequiredFields = false
  ;

  CreateBlockParams._() : super();
  factory CreateBlockParams({
    $core.String? id,
    $0.RepeatedRevision? revisions,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (revisions != null) {
      _result.revisions = revisions;
    }
    return _result;
  }
  factory CreateBlockParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateBlockParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateBlockParams clone() => CreateBlockParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateBlockParams copyWith(void Function(CreateBlockParams) updates) => super.copyWith((message) => updates(message as CreateBlockParams)) as CreateBlockParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateBlockParams create() => CreateBlockParams._();
  CreateBlockParams createEmptyInstance() => create();
  static $pb.PbList<CreateBlockParams> createRepeated() => $pb.PbList<CreateBlockParams>();
  @$core.pragma('dart2js:noInline')
  static CreateBlockParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateBlockParams>(create);
  static CreateBlockParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $0.RepeatedRevision get revisions => $_getN(1);
  @$pb.TagNumber(2)
  set revisions($0.RepeatedRevision v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRevisions() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevisions() => clearField(2);
  @$pb.TagNumber(2)
  $0.RepeatedRevision ensureRevisions() => $_ensure(1);
}

class BlockInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlockInfo', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'text')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'baseRevId')
    ..hasRequiredFields = false
  ;

  BlockInfo._() : super();
  factory BlockInfo({
    $core.String? docId,
    $core.String? text,
    $fixnum.Int64? revId,
    $fixnum.Int64? baseRevId,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (text != null) {
      _result.text = text;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    if (baseRevId != null) {
      _result.baseRevId = baseRevId;
    }
    return _result;
  }
  factory BlockInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockInfo clone() => BlockInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockInfo copyWith(void Function(BlockInfo) updates) => super.copyWith((message) => updates(message as BlockInfo)) as BlockInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlockInfo create() => BlockInfo._();
  BlockInfo createEmptyInstance() => create();
  static $pb.PbList<BlockInfo> createRepeated() => $pb.PbList<BlockInfo>();
  @$core.pragma('dart2js:noInline')
  static BlockInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockInfo>(create);
  static BlockInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revId => $_getI64(2);
  @$pb.TagNumber(3)
  set revId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRevId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevId() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get baseRevId => $_getI64(3);
  @$pb.TagNumber(4)
  set baseRevId($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBaseRevId() => $_has(3);
  @$pb.TagNumber(4)
  void clearBaseRevId() => clearField(4);
}

class ResetDocumentParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ResetDocumentParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aOM<$0.RepeatedRevision>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revisions', subBuilder: $0.RepeatedRevision.create)
    ..hasRequiredFields = false
  ;

  ResetDocumentParams._() : super();
  factory ResetDocumentParams({
    $core.String? docId,
    $0.RepeatedRevision? revisions,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (revisions != null) {
      _result.revisions = revisions;
    }
    return _result;
  }
  factory ResetDocumentParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResetDocumentParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResetDocumentParams clone() => ResetDocumentParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResetDocumentParams copyWith(void Function(ResetDocumentParams) updates) => super.copyWith((message) => updates(message as ResetDocumentParams)) as ResetDocumentParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ResetDocumentParams create() => ResetDocumentParams._();
  ResetDocumentParams createEmptyInstance() => create();
  static $pb.PbList<ResetDocumentParams> createRepeated() => $pb.PbList<ResetDocumentParams>();
  @$core.pragma('dart2js:noInline')
  static ResetDocumentParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResetDocumentParams>(create);
  static ResetDocumentParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  $0.RepeatedRevision get revisions => $_getN(1);
  @$pb.TagNumber(2)
  set revisions($0.RepeatedRevision v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRevisions() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevisions() => clearField(2);
  @$pb.TagNumber(2)
  $0.RepeatedRevision ensureRevisions() => $_ensure(1);
}

class BlockDelta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlockDelta', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deltaJson')
    ..hasRequiredFields = false
  ;

  BlockDelta._() : super();
  factory BlockDelta({
    $core.String? blockId,
    $core.String? deltaJson,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (deltaJson != null) {
      _result.deltaJson = deltaJson;
    }
    return _result;
  }
  factory BlockDelta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockDelta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockDelta clone() => BlockDelta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockDelta copyWith(void Function(BlockDelta) updates) => super.copyWith((message) => updates(message as BlockDelta)) as BlockDelta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlockDelta create() => BlockDelta._();
  BlockDelta createEmptyInstance() => create();
  static $pb.PbList<BlockDelta> createRepeated() => $pb.PbList<BlockDelta>();
  @$core.pragma('dart2js:noInline')
  static BlockDelta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockDelta>(create);
  static BlockDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get deltaJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set deltaJson($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeltaJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeltaJson() => clearField(2);
}

class NewDocUser extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'NewDocUser', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..hasRequiredFields = false
  ;

  NewDocUser._() : super();
  factory NewDocUser({
    $core.String? userId,
    $fixnum.Int64? revId,
    $core.String? docId,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    if (docId != null) {
      _result.docId = docId;
    }
    return _result;
  }
  factory NewDocUser.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NewDocUser.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NewDocUser clone() => NewDocUser()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NewDocUser copyWith(void Function(NewDocUser) updates) => super.copyWith((message) => updates(message as NewDocUser)) as NewDocUser; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NewDocUser create() => NewDocUser._();
  NewDocUser createEmptyInstance() => create();
  static $pb.PbList<NewDocUser> createRepeated() => $pb.PbList<NewDocUser>();
  @$core.pragma('dart2js:noInline')
  static NewDocUser getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NewDocUser>(create);
  static NewDocUser? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revId => $_getI64(1);
  @$pb.TagNumber(2)
  set revId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRevId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get docId => $_getSZ(2);
  @$pb.TagNumber(3)
  set docId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDocId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDocId() => clearField(3);
}

class BlockId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlockId', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  BlockId._() : super();
  factory BlockId({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory BlockId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockId clone() => BlockId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockId copyWith(void Function(BlockId) updates) => super.copyWith((message) => updates(message as BlockId)) as BlockId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlockId create() => BlockId._();
  BlockId createEmptyInstance() => create();
  static $pb.PbList<BlockId> createRepeated() => $pb.PbList<BlockId>();
  @$core.pragma('dart2js:noInline')
  static BlockId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockId>(create);
  static BlockId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

