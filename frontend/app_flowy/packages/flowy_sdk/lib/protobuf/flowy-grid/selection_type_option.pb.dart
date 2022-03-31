///
//  Generated code. Do not modify.
//  source: selection_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'selection_type_option.pbenum.dart';

export 'selection_type_option.pbenum.dart';

class SingleSelectTypeOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SingleSelectTypeOption', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  SingleSelectTypeOption._() : super();
  factory SingleSelectTypeOption({
    $core.Iterable<SelectOption>? options,
    $core.bool? disableColor,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (disableColor != null) {
      _result.disableColor = disableColor;
    }
    return _result;
  }
  factory SingleSelectTypeOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SingleSelectTypeOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SingleSelectTypeOption clone() => SingleSelectTypeOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SingleSelectTypeOption copyWith(void Function(SingleSelectTypeOption) updates) => super.copyWith((message) => updates(message as SingleSelectTypeOption)) as SingleSelectTypeOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SingleSelectTypeOption create() => SingleSelectTypeOption._();
  SingleSelectTypeOption createEmptyInstance() => create();
  static $pb.PbList<SingleSelectTypeOption> createRepeated() => $pb.PbList<SingleSelectTypeOption>();
  @$core.pragma('dart2js:noInline')
  static SingleSelectTypeOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SingleSelectTypeOption>(create);
  static SingleSelectTypeOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOption> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get disableColor => $_getBF(1);
  @$pb.TagNumber(2)
  set disableColor($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisableColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisableColor() => clearField(2);
}

class MultiSelectTypeOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MultiSelectTypeOption', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  MultiSelectTypeOption._() : super();
  factory MultiSelectTypeOption({
    $core.Iterable<SelectOption>? options,
    $core.bool? disableColor,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (disableColor != null) {
      _result.disableColor = disableColor;
    }
    return _result;
  }
  factory MultiSelectTypeOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MultiSelectTypeOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MultiSelectTypeOption clone() => MultiSelectTypeOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MultiSelectTypeOption copyWith(void Function(MultiSelectTypeOption) updates) => super.copyWith((message) => updates(message as MultiSelectTypeOption)) as MultiSelectTypeOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MultiSelectTypeOption create() => MultiSelectTypeOption._();
  MultiSelectTypeOption createEmptyInstance() => create();
  static $pb.PbList<MultiSelectTypeOption> createRepeated() => $pb.PbList<MultiSelectTypeOption>();
  @$core.pragma('dart2js:noInline')
  static MultiSelectTypeOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MultiSelectTypeOption>(create);
  static MultiSelectTypeOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOption> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get disableColor => $_getBF(1);
  @$pb.TagNumber(2)
  set disableColor($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisableColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisableColor() => clearField(2);
}

class SelectOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOption', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..e<SelectOptionColor>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'color', $pb.PbFieldType.OE, defaultOrMaker: SelectOptionColor.Purple, valueOf: SelectOptionColor.valueOf, enumValues: SelectOptionColor.values)
    ..hasRequiredFields = false
  ;

  SelectOption._() : super();
  factory SelectOption({
    $core.String? id,
    $core.String? name,
    SelectOptionColor? color,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (color != null) {
      _result.color = color;
    }
    return _result;
  }
  factory SelectOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOption clone() => SelectOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOption copyWith(void Function(SelectOption) updates) => super.copyWith((message) => updates(message as SelectOption)) as SelectOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOption create() => SelectOption._();
  SelectOption createEmptyInstance() => create();
  static $pb.PbList<SelectOption> createRepeated() => $pb.PbList<SelectOption>();
  @$core.pragma('dart2js:noInline')
  static SelectOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOption>(create);
  static SelectOption? _defaultInstance;

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
  SelectOptionColor get color => $_getN(2);
  @$pb.TagNumber(3)
  set color(SelectOptionColor v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => clearField(3);
}

