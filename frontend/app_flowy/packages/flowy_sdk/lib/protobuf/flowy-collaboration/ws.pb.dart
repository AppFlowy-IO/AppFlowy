///
//  Generated code. Do not modify.
//  source: ws.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'ws.pbenum.dart';

export 'ws.pbenum.dart';

class WsDocumentData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'WsDocumentData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..e<WsDocumentDataType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: WsDocumentDataType.Acked, valueOf: WsDocumentDataType.valueOf, enumValues: WsDocumentDataType.values)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  WsDocumentData._() : super();
  factory WsDocumentData({
    $core.String? docId,
    WsDocumentDataType? ty,
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
  factory WsDocumentData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WsDocumentData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WsDocumentData clone() => WsDocumentData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WsDocumentData copyWith(void Function(WsDocumentData) updates) => super.copyWith((message) => updates(message as WsDocumentData)) as WsDocumentData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static WsDocumentData create() => WsDocumentData._();
  WsDocumentData createEmptyInstance() => create();
  static $pb.PbList<WsDocumentData> createRepeated() => $pb.PbList<WsDocumentData>();
  @$core.pragma('dart2js:noInline')
  static WsDocumentData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WsDocumentData>(create);
  static WsDocumentData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  WsDocumentDataType get ty => $_getN(1);
  @$pb.TagNumber(2)
  set ty(WsDocumentDataType v) { setField(2, v); }
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

class DocumentConnected extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DocumentConnected', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..hasRequiredFields = false
  ;

  DocumentConnected._() : super();
  factory DocumentConnected({
    $core.String? userId,
    $core.String? docId,
    $fixnum.Int64? revId,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (docId != null) {
      _result.docId = docId;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    return _result;
  }
  factory DocumentConnected.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DocumentConnected.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DocumentConnected clone() => DocumentConnected()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DocumentConnected copyWith(void Function(DocumentConnected) updates) => super.copyWith((message) => updates(message as DocumentConnected)) as DocumentConnected; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DocumentConnected create() => DocumentConnected._();
  DocumentConnected createEmptyInstance() => create();
  static $pb.PbList<DocumentConnected> createRepeated() => $pb.PbList<DocumentConnected>();
  @$core.pragma('dart2js:noInline')
  static DocumentConnected getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DocumentConnected>(create);
  static DocumentConnected? _defaultInstance;

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
  $fixnum.Int64 get revId => $_getI64(2);
  @$pb.TagNumber(3)
  set revId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRevId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevId() => clearField(3);
}

