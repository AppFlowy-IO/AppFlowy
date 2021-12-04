///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'observable.pbenum.dart';

export 'observable.pbenum.dart';

class NetworkState extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'NetworkState', createEmptyInstance: create)
    ..e<NetworkType>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: NetworkType.UnknownNetworkType, valueOf: NetworkType.valueOf, enumValues: NetworkType.values)
    ..hasRequiredFields = false
  ;

  NetworkState._() : super();
  factory NetworkState({
    NetworkType? ty,
  }) {
    final _result = create();
    if (ty != null) {
      _result.ty = ty;
    }
    return _result;
  }
  factory NetworkState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NetworkState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NetworkState clone() => NetworkState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NetworkState copyWith(void Function(NetworkState) updates) => super.copyWith((message) => updates(message as NetworkState)) as NetworkState; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NetworkState create() => NetworkState._();
  NetworkState createEmptyInstance() => create();
  static $pb.PbList<NetworkState> createRepeated() => $pb.PbList<NetworkState>();
  @$core.pragma('dart2js:noInline')
  static NetworkState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NetworkState>(create);
  static NetworkState? _defaultInstance;

  @$pb.TagNumber(1)
  NetworkType get ty => $_getN(0);
  @$pb.TagNumber(1)
  set ty(NetworkType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTy() => $_has(0);
  @$pb.TagNumber(1)
  void clearTy() => clearField(1);
}

