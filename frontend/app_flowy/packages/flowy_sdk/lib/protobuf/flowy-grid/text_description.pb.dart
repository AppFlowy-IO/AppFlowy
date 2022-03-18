///
//  Generated code. Do not modify.
//  source: text_description.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class RichTextDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RichTextDescription', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'format')
    ..hasRequiredFields = false
  ;

  RichTextDescription._() : super();
  factory RichTextDescription({
    $core.String? format,
  }) {
    final _result = create();
    if (format != null) {
      _result.format = format;
    }
    return _result;
  }
  factory RichTextDescription.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RichTextDescription.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RichTextDescription clone() => RichTextDescription()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RichTextDescription copyWith(void Function(RichTextDescription) updates) => super.copyWith((message) => updates(message as RichTextDescription)) as RichTextDescription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RichTextDescription create() => RichTextDescription._();
  RichTextDescription createEmptyInstance() => create();
  static $pb.PbList<RichTextDescription> createRepeated() => $pb.PbList<RichTextDescription>();
  @$core.pragma('dart2js:noInline')
  static RichTextDescription getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RichTextDescription>(create);
  static RichTextDescription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get format => $_getSZ(0);
  @$pb.TagNumber(1)
  set format($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => clearField(1);
}

