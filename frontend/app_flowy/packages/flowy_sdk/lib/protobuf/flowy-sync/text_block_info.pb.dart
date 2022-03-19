///
//  Generated code. Do not modify.
//  source: text_block_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'revision.pb.dart' as $0;

class CreateTextBlockParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateTextBlockParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOM<$0.RepeatedRevision>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revisions', subBuilder: $0.RepeatedRevision.create)
    ..hasRequiredFields = false
  ;

  CreateTextBlockParams._() : super();
  factory CreateTextBlockParams({
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
  factory CreateTextBlockParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateTextBlockParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateTextBlockParams clone() => CreateTextBlockParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateTextBlockParams copyWith(void Function(CreateTextBlockParams) updates) => super.copyWith((message) => updates(message as CreateTextBlockParams)) as CreateTextBlockParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateTextBlockParams create() => CreateTextBlockParams._();
  CreateTextBlockParams createEmptyInstance() => create();
  static $pb.PbList<CreateTextBlockParams> createRepeated() => $pb.PbList<CreateTextBlockParams>();
  @$core.pragma('dart2js:noInline')
  static CreateTextBlockParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateTextBlockParams>(create);
  static CreateTextBlockParams? _defaultInstance;

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

class TextBlockInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TextBlockInfo', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'text')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'baseRevId')
    ..hasRequiredFields = false
  ;

  TextBlockInfo._() : super();
  factory TextBlockInfo({
    $core.String? blockId,
    $core.String? text,
    $fixnum.Int64? revId,
    $fixnum.Int64? baseRevId,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
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
  factory TextBlockInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextBlockInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextBlockInfo clone() => TextBlockInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextBlockInfo copyWith(void Function(TextBlockInfo) updates) => super.copyWith((message) => updates(message as TextBlockInfo)) as TextBlockInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TextBlockInfo create() => TextBlockInfo._();
  TextBlockInfo createEmptyInstance() => create();
  static $pb.PbList<TextBlockInfo> createRepeated() => $pb.PbList<TextBlockInfo>();
  @$core.pragma('dart2js:noInline')
  static TextBlockInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextBlockInfo>(create);
  static TextBlockInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

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

class ResetTextBlockParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ResetTextBlockParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..aOM<$0.RepeatedRevision>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revisions', subBuilder: $0.RepeatedRevision.create)
    ..hasRequiredFields = false
  ;

  ResetTextBlockParams._() : super();
  factory ResetTextBlockParams({
    $core.String? blockId,
    $0.RepeatedRevision? revisions,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (revisions != null) {
      _result.revisions = revisions;
    }
    return _result;
  }
  factory ResetTextBlockParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResetTextBlockParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResetTextBlockParams clone() => ResetTextBlockParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResetTextBlockParams copyWith(void Function(ResetTextBlockParams) updates) => super.copyWith((message) => updates(message as ResetTextBlockParams)) as ResetTextBlockParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ResetTextBlockParams create() => ResetTextBlockParams._();
  ResetTextBlockParams createEmptyInstance() => create();
  static $pb.PbList<ResetTextBlockParams> createRepeated() => $pb.PbList<ResetTextBlockParams>();
  @$core.pragma('dart2js:noInline')
  static ResetTextBlockParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResetTextBlockParams>(create);
  static ResetTextBlockParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

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

class TextBlockDelta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TextBlockDelta', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deltaStr')
    ..hasRequiredFields = false
  ;

  TextBlockDelta._() : super();
  factory TextBlockDelta({
    $core.String? blockId,
    $core.String? deltaStr,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    if (deltaStr != null) {
      _result.deltaStr = deltaStr;
    }
    return _result;
  }
  factory TextBlockDelta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextBlockDelta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextBlockDelta clone() => TextBlockDelta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextBlockDelta copyWith(void Function(TextBlockDelta) updates) => super.copyWith((message) => updates(message as TextBlockDelta)) as TextBlockDelta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TextBlockDelta create() => TextBlockDelta._();
  TextBlockDelta createEmptyInstance() => create();
  static $pb.PbList<TextBlockDelta> createRepeated() => $pb.PbList<TextBlockDelta>();
  @$core.pragma('dart2js:noInline')
  static TextBlockDelta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextBlockDelta>(create);
  static TextBlockDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get blockId => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get deltaStr => $_getSZ(1);
  @$pb.TagNumber(2)
  set deltaStr($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeltaStr() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeltaStr() => clearField(2);
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

class TextBlockId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TextBlockId', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  TextBlockId._() : super();
  factory TextBlockId({
    $core.String? value,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory TextBlockId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextBlockId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextBlockId clone() => TextBlockId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextBlockId copyWith(void Function(TextBlockId) updates) => super.copyWith((message) => updates(message as TextBlockId)) as TextBlockId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TextBlockId create() => TextBlockId._();
  TextBlockId createEmptyInstance() => create();
  static $pb.PbList<TextBlockId> createRepeated() => $pb.PbList<TextBlockId>();
  @$core.pragma('dart2js:noInline')
  static TextBlockId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextBlockId>(create);
  static TextBlockId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

