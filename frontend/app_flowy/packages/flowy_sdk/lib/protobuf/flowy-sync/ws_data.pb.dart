///
//  Generated code. Do not modify.
//  source: ws_data.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'revision.pb.dart' as $0;

import 'ws_data.pbenum.dart';

export 'ws_data.pbenum.dart';

class ClientRevisionWSData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ClientRevisionWSData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'objectId')
    ..e<ClientRevisionWSDataType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: ClientRevisionWSDataType.ClientPushRev, valueOf: ClientRevisionWSDataType.valueOf, enumValues: ClientRevisionWSDataType.values)
    ..aOM<$0.RepeatedRevision>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revisions', subBuilder: $0.RepeatedRevision.create)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataId')
    ..hasRequiredFields = false
  ;

  ClientRevisionWSData._() : super();
  factory ClientRevisionWSData({
    $core.String? objectId,
    ClientRevisionWSDataType? ty,
    $0.RepeatedRevision? revisions,
    $core.String? dataId,
  }) {
    final _result = create();
    if (objectId != null) {
      _result.objectId = objectId;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    if (revisions != null) {
      _result.revisions = revisions;
    }
    if (dataId != null) {
      _result.dataId = dataId;
    }
    return _result;
  }
  factory ClientRevisionWSData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClientRevisionWSData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClientRevisionWSData clone() => ClientRevisionWSData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClientRevisionWSData copyWith(void Function(ClientRevisionWSData) updates) => super.copyWith((message) => updates(message as ClientRevisionWSData)) as ClientRevisionWSData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClientRevisionWSData create() => ClientRevisionWSData._();
  ClientRevisionWSData createEmptyInstance() => create();
  static $pb.PbList<ClientRevisionWSData> createRepeated() => $pb.PbList<ClientRevisionWSData>();
  @$core.pragma('dart2js:noInline')
  static ClientRevisionWSData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientRevisionWSData>(create);
  static ClientRevisionWSData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objectId => $_getSZ(0);
  @$pb.TagNumber(1)
  set objectId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasObjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjectId() => clearField(1);

  @$pb.TagNumber(2)
  ClientRevisionWSDataType get ty => $_getN(1);
  @$pb.TagNumber(2)
  set ty(ClientRevisionWSDataType v) { setField(2, v); }
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
  $core.String get dataId => $_getSZ(3);
  @$pb.TagNumber(4)
  set dataId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDataId() => $_has(3);
  @$pb.TagNumber(4)
  void clearDataId() => clearField(4);
}

class ServerRevisionWSData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ServerRevisionWSData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'objectId')
    ..e<ServerRevisionWSDataType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: ServerRevisionWSDataType.ServerAck, valueOf: ServerRevisionWSDataType.valueOf, enumValues: ServerRevisionWSDataType.values)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  ServerRevisionWSData._() : super();
  factory ServerRevisionWSData({
    $core.String? objectId,
    ServerRevisionWSDataType? ty,
    $core.List<$core.int>? data,
  }) {
    final _result = create();
    if (objectId != null) {
      _result.objectId = objectId;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory ServerRevisionWSData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerRevisionWSData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerRevisionWSData clone() => ServerRevisionWSData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerRevisionWSData copyWith(void Function(ServerRevisionWSData) updates) => super.copyWith((message) => updates(message as ServerRevisionWSData)) as ServerRevisionWSData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ServerRevisionWSData create() => ServerRevisionWSData._();
  ServerRevisionWSData createEmptyInstance() => create();
  static $pb.PbList<ServerRevisionWSData> createRepeated() => $pb.PbList<ServerRevisionWSData>();
  @$core.pragma('dart2js:noInline')
  static ServerRevisionWSData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerRevisionWSData>(create);
  static ServerRevisionWSData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objectId => $_getSZ(0);
  @$pb.TagNumber(1)
  set objectId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasObjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjectId() => clearField(1);

  @$pb.TagNumber(2)
  ServerRevisionWSDataType get ty => $_getN(1);
  @$pb.TagNumber(2)
  set ty(ServerRevisionWSDataType v) { setField(2, v); }
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

