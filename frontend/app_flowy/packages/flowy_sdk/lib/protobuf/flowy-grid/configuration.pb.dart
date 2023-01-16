///
//  Generated code. Do not modify.
//  source: configuration.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'configuration.pbenum.dart';

export 'configuration.pbenum.dart';

class UrlGroupConfigurationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UrlGroupConfigurationPB', createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hideEmpty')
    ..hasRequiredFields = false
  ;

  UrlGroupConfigurationPB._() : super();
  factory UrlGroupConfigurationPB({
    $core.bool? hideEmpty,
  }) {
    final _result = create();
    if (hideEmpty != null) {
      _result.hideEmpty = hideEmpty;
    }
    return _result;
  }
  factory UrlGroupConfigurationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UrlGroupConfigurationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UrlGroupConfigurationPB clone() => UrlGroupConfigurationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UrlGroupConfigurationPB copyWith(void Function(UrlGroupConfigurationPB) updates) => super.copyWith((message) => updates(message as UrlGroupConfigurationPB)) as UrlGroupConfigurationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UrlGroupConfigurationPB create() => UrlGroupConfigurationPB._();
  UrlGroupConfigurationPB createEmptyInstance() => create();
  static $pb.PbList<UrlGroupConfigurationPB> createRepeated() => $pb.PbList<UrlGroupConfigurationPB>();
  @$core.pragma('dart2js:noInline')
  static UrlGroupConfigurationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UrlGroupConfigurationPB>(create);
  static UrlGroupConfigurationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hideEmpty => $_getBF(0);
  @$pb.TagNumber(1)
  set hideEmpty($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHideEmpty() => $_has(0);
  @$pb.TagNumber(1)
  void clearHideEmpty() => clearField(1);
}

class TextGroupConfigurationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TextGroupConfigurationPB', createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hideEmpty')
    ..hasRequiredFields = false
  ;

  TextGroupConfigurationPB._() : super();
  factory TextGroupConfigurationPB({
    $core.bool? hideEmpty,
  }) {
    final _result = create();
    if (hideEmpty != null) {
      _result.hideEmpty = hideEmpty;
    }
    return _result;
  }
  factory TextGroupConfigurationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextGroupConfigurationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextGroupConfigurationPB clone() => TextGroupConfigurationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextGroupConfigurationPB copyWith(void Function(TextGroupConfigurationPB) updates) => super.copyWith((message) => updates(message as TextGroupConfigurationPB)) as TextGroupConfigurationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TextGroupConfigurationPB create() => TextGroupConfigurationPB._();
  TextGroupConfigurationPB createEmptyInstance() => create();
  static $pb.PbList<TextGroupConfigurationPB> createRepeated() => $pb.PbList<TextGroupConfigurationPB>();
  @$core.pragma('dart2js:noInline')
  static TextGroupConfigurationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextGroupConfigurationPB>(create);
  static TextGroupConfigurationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hideEmpty => $_getBF(0);
  @$pb.TagNumber(1)
  set hideEmpty($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHideEmpty() => $_has(0);
  @$pb.TagNumber(1)
  void clearHideEmpty() => clearField(1);
}

class SelectOptionGroupConfigurationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionGroupConfigurationPB', createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hideEmpty')
    ..hasRequiredFields = false
  ;

  SelectOptionGroupConfigurationPB._() : super();
  factory SelectOptionGroupConfigurationPB({
    $core.bool? hideEmpty,
  }) {
    final _result = create();
    if (hideEmpty != null) {
      _result.hideEmpty = hideEmpty;
    }
    return _result;
  }
  factory SelectOptionGroupConfigurationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionGroupConfigurationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionGroupConfigurationPB clone() => SelectOptionGroupConfigurationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionGroupConfigurationPB copyWith(void Function(SelectOptionGroupConfigurationPB) updates) => super.copyWith((message) => updates(message as SelectOptionGroupConfigurationPB)) as SelectOptionGroupConfigurationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionGroupConfigurationPB create() => SelectOptionGroupConfigurationPB._();
  SelectOptionGroupConfigurationPB createEmptyInstance() => create();
  static $pb.PbList<SelectOptionGroupConfigurationPB> createRepeated() => $pb.PbList<SelectOptionGroupConfigurationPB>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionGroupConfigurationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionGroupConfigurationPB>(create);
  static SelectOptionGroupConfigurationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hideEmpty => $_getBF(0);
  @$pb.TagNumber(1)
  set hideEmpty($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHideEmpty() => $_has(0);
  @$pb.TagNumber(1)
  void clearHideEmpty() => clearField(1);
}

class GroupRecordPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GroupRecordPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'groupId')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visible')
    ..hasRequiredFields = false
  ;

  GroupRecordPB._() : super();
  factory GroupRecordPB({
    $core.String? groupId,
    $core.bool? visible,
  }) {
    final _result = create();
    if (groupId != null) {
      _result.groupId = groupId;
    }
    if (visible != null) {
      _result.visible = visible;
    }
    return _result;
  }
  factory GroupRecordPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupRecordPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupRecordPB clone() => GroupRecordPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupRecordPB copyWith(void Function(GroupRecordPB) updates) => super.copyWith((message) => updates(message as GroupRecordPB)) as GroupRecordPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GroupRecordPB create() => GroupRecordPB._();
  GroupRecordPB createEmptyInstance() => create();
  static $pb.PbList<GroupRecordPB> createRepeated() => $pb.PbList<GroupRecordPB>();
  @$core.pragma('dart2js:noInline')
  static GroupRecordPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupRecordPB>(create);
  static GroupRecordPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get visible => $_getBF(1);
  @$pb.TagNumber(2)
  set visible($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVisible() => $_has(1);
  @$pb.TagNumber(2)
  void clearVisible() => clearField(2);
}

class NumberGroupConfigurationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'NumberGroupConfigurationPB', createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hideEmpty')
    ..hasRequiredFields = false
  ;

  NumberGroupConfigurationPB._() : super();
  factory NumberGroupConfigurationPB({
    $core.bool? hideEmpty,
  }) {
    final _result = create();
    if (hideEmpty != null) {
      _result.hideEmpty = hideEmpty;
    }
    return _result;
  }
  factory NumberGroupConfigurationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NumberGroupConfigurationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NumberGroupConfigurationPB clone() => NumberGroupConfigurationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NumberGroupConfigurationPB copyWith(void Function(NumberGroupConfigurationPB) updates) => super.copyWith((message) => updates(message as NumberGroupConfigurationPB)) as NumberGroupConfigurationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NumberGroupConfigurationPB create() => NumberGroupConfigurationPB._();
  NumberGroupConfigurationPB createEmptyInstance() => create();
  static $pb.PbList<NumberGroupConfigurationPB> createRepeated() => $pb.PbList<NumberGroupConfigurationPB>();
  @$core.pragma('dart2js:noInline')
  static NumberGroupConfigurationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NumberGroupConfigurationPB>(create);
  static NumberGroupConfigurationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hideEmpty => $_getBF(0);
  @$pb.TagNumber(1)
  set hideEmpty($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHideEmpty() => $_has(0);
  @$pb.TagNumber(1)
  void clearHideEmpty() => clearField(1);
}

class DateGroupConfigurationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateGroupConfigurationPB', createEmptyInstance: create)
    ..e<DateCondition>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'condition', $pb.PbFieldType.OE, defaultOrMaker: DateCondition.Relative, valueOf: DateCondition.valueOf, enumValues: DateCondition.values)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hideEmpty')
    ..hasRequiredFields = false
  ;

  DateGroupConfigurationPB._() : super();
  factory DateGroupConfigurationPB({
    DateCondition? condition,
    $core.bool? hideEmpty,
  }) {
    final _result = create();
    if (condition != null) {
      _result.condition = condition;
    }
    if (hideEmpty != null) {
      _result.hideEmpty = hideEmpty;
    }
    return _result;
  }
  factory DateGroupConfigurationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateGroupConfigurationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateGroupConfigurationPB clone() => DateGroupConfigurationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateGroupConfigurationPB copyWith(void Function(DateGroupConfigurationPB) updates) => super.copyWith((message) => updates(message as DateGroupConfigurationPB)) as DateGroupConfigurationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateGroupConfigurationPB create() => DateGroupConfigurationPB._();
  DateGroupConfigurationPB createEmptyInstance() => create();
  static $pb.PbList<DateGroupConfigurationPB> createRepeated() => $pb.PbList<DateGroupConfigurationPB>();
  @$core.pragma('dart2js:noInline')
  static DateGroupConfigurationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateGroupConfigurationPB>(create);
  static DateGroupConfigurationPB? _defaultInstance;

  @$pb.TagNumber(1)
  DateCondition get condition => $_getN(0);
  @$pb.TagNumber(1)
  set condition(DateCondition v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCondition() => $_has(0);
  @$pb.TagNumber(1)
  void clearCondition() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get hideEmpty => $_getBF(1);
  @$pb.TagNumber(2)
  set hideEmpty($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHideEmpty() => $_has(1);
  @$pb.TagNumber(2)
  void clearHideEmpty() => clearField(2);
}

class CheckboxGroupConfigurationPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CheckboxGroupConfigurationPB', createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hideEmpty')
    ..hasRequiredFields = false
  ;

  CheckboxGroupConfigurationPB._() : super();
  factory CheckboxGroupConfigurationPB({
    $core.bool? hideEmpty,
  }) {
    final _result = create();
    if (hideEmpty != null) {
      _result.hideEmpty = hideEmpty;
    }
    return _result;
  }
  factory CheckboxGroupConfigurationPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CheckboxGroupConfigurationPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CheckboxGroupConfigurationPB clone() => CheckboxGroupConfigurationPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CheckboxGroupConfigurationPB copyWith(void Function(CheckboxGroupConfigurationPB) updates) => super.copyWith((message) => updates(message as CheckboxGroupConfigurationPB)) as CheckboxGroupConfigurationPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CheckboxGroupConfigurationPB create() => CheckboxGroupConfigurationPB._();
  CheckboxGroupConfigurationPB createEmptyInstance() => create();
  static $pb.PbList<CheckboxGroupConfigurationPB> createRepeated() => $pb.PbList<CheckboxGroupConfigurationPB>();
  @$core.pragma('dart2js:noInline')
  static CheckboxGroupConfigurationPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckboxGroupConfigurationPB>(create);
  static CheckboxGroupConfigurationPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hideEmpty => $_getBF(0);
  @$pb.TagNumber(1)
  set hideEmpty($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHideEmpty() => $_has(0);
  @$pb.TagNumber(1)
  void clearHideEmpty() => clearField(1);
}

