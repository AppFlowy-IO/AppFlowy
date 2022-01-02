///
//  Generated code. Do not modify.
//  source: ws.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'revision.pb.dart' as $0;

import 'ws.pbenum.dart';

export 'ws.pbenum.dart';

class DocumentClientWSData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DocumentClientWSData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..e<DocumentClientWSDataType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: DocumentClientWSDataType.ClientPushRev, valueOf: DocumentClientWSDataType.valueOf, enumValues: DocumentClientWSDataType.values)
    ..aOM<$0.RepeatedRevision>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revisions', subBuilder: $0.RepeatedRevision.create)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..hasRequiredFields = false
  ;

  DocumentClientWSData._() : super();
  factory DocumentClientWSData({
    $core.String? docId,
    DocumentClientWSDataType? ty,
    $0.RepeatedRevision? revisions,
    $core.String? id,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    if (revisions != null) {
      _result.revisions = revisions;
    }
    if (id != null) {
      _result.id = id;
    }
    return _result;
  }
  factory DocumentClientWSData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DocumentClientWSData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DocumentClientWSData clone() => DocumentClientWSData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DocumentClientWSData copyWith(void Function(DocumentClientWSData) updates) => super.copyWith((message) => updates(message as DocumentClientWSData)) as DocumentClientWSData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DocumentClientWSData create() => DocumentClientWSData._();
  DocumentClientWSData createEmptyInstance() => create();
  static $pb.PbList<DocumentClientWSData> createRepeated() => $pb.PbList<DocumentClientWSData>();
  @$core.pragma('dart2js:noInline')
  static DocumentClientWSData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DocumentClientWSData>(create);
  static DocumentClientWSData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  DocumentClientWSDataType get ty => $_getN(1);
  @$pb.TagNumber(2)
  set ty(DocumentClientWSDataType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTy() => $_has(1);
  @$pb.TagNumber(2)
  void clearTy() => clearField(2);

  @$pb.TagNumber(3)
  $0.RepeatedRevision get revisions => $_getN(2);
  @$pb.TagNumber(3)
  set revisions($0.RepeatedRevision v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasRevisions() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevisions() => clearField(3);
  @$pb.TagNumber(3)
  $0.RepeatedRevision ensureRevisions() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get id => $_getSZ(3);
  @$pb.TagNumber(4)
  set id($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasId() => $_has(3);
  @$pb.TagNumber(4)
  void clearId() => clearField(4);
}

class DocumentServerWSData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DocumentServerWSData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..e<DocumentServerWSDataType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: DocumentServerWSDataType.ServerAck, valueOf: DocumentServerWSDataType.valueOf, enumValues: DocumentServerWSDataType.values)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  DocumentServerWSData._() : super();
  factory DocumentServerWSData({
    $core.String? docId,
    DocumentServerWSDataType? ty,
    $core.List<$core.int>? data,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory DocumentServerWSData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DocumentServerWSData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DocumentServerWSData clone() => DocumentServerWSData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DocumentServerWSData copyWith(void Function(DocumentServerWSData) updates) => super.copyWith((message) => updates(message as DocumentServerWSData)) as DocumentServerWSData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DocumentServerWSData create() => DocumentServerWSData._();
  DocumentServerWSData createEmptyInstance() => create();
  static $pb.PbList<DocumentServerWSData> createRepeated() => $pb.PbList<DocumentServerWSData>();
  @$core.pragma('dart2js:noInline')
  static DocumentServerWSData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DocumentServerWSData>(create);
  static DocumentServerWSData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  DocumentServerWSDataType get ty => $_getN(1);
  @$pb.TagNumber(2)
  set ty(DocumentServerWSDataType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTy() => $_has(1);
  @$pb.TagNumber(2)
  void clearTy() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => clearField(3);
}

class NewDocumentUser extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'NewDocumentUser', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revisionData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  NewDocumentUser._() : super();
  factory NewDocumentUser({
    $core.String? userId,
    $core.String? docId,
    $core.List<$core.int>? revisionData,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (docId != null) {
      _result.docId = docId;
    }
    if (revisionData != null) {
      _result.revisionData = revisionData;
    }
    return _result;
  }
  factory NewDocumentUser.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NewDocumentUser.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NewDocumentUser clone() => NewDocumentUser()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NewDocumentUser copyWith(void Function(NewDocumentUser) updates) => super.copyWith((message) => updates(message as NewDocumentUser)) as NewDocumentUser; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NewDocumentUser create() => NewDocumentUser._();
  NewDocumentUser createEmptyInstance() => create();
  static $pb.PbList<NewDocumentUser> createRepeated() => $pb.PbList<NewDocumentUser>();
  @$core.pragma('dart2js:noInline')
  static NewDocumentUser getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NewDocumentUser>(create);
  static NewDocumentUser? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get docId => $_getSZ(1);
  @$pb.TagNumber(2)
  set docId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDocId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDocId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get revisionData => $_getN(2);
  @$pb.TagNumber(3)
  set revisionData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRevisionData() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevisionData() => clearField(3);
}

