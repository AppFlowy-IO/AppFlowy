import 'dart:typed_data';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_type_list.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_type_option.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'type_option/number.dart';

typedef SelectFieldCallback = void Function(Field, Uint8List);

class FieldTypeSwitcher extends StatelessWidget {
  final SwitchFieldContext switchContext;
  final SelectFieldCallback onSelected;

  const FieldTypeSwitcher({
    required this.switchContext,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SwitchFieldTypeBloc>(param1: switchContext),
      child: BlocBuilder<SwitchFieldTypeBloc, SwitchFieldTypeState>(
        builder: (context, state) {
          List<Widget> children = [
            _switchFieldTypeButton(context, state.field),
          ];

          final builder = _makeTypeOptionBuild(
            fieldType: state.field.fieldType,
            typeOptionData: state.typeOptionData,
            typeOptionDataCallback: (newTypeOptionData) {
              context.read<SwitchFieldTypeBloc>().add(SwitchFieldTypeEvent.didUpdateTypeOptionData(newTypeOptionData));
            },
          );

          final typeOptionWidget = builder.customWidget;
          if (typeOptionWidget != null) {
            children.add(typeOptionWidget);
          }

          return ListView(
            shrinkWrap: true,
            children: children,
          );
        },
      ),
    );
  }

  Widget _switchFieldTypeButton(BuildContext context, Field field) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: 36,
      child: FlowyButton(
        text: FlowyText.medium(field.fieldType.title(), fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        hoverColor: theme.hover,
        onTap: () => FieldTypeList.show(context, (fieldType) {
          context.read<SwitchFieldTypeBloc>().add(SwitchFieldTypeEvent.toFieldType(fieldType));
        }),
        leftIcon: svg(field.fieldType.iconName(), color: theme.iconColor),
        rightIcon: svg("grid/more", color: theme.iconColor),
      ),
    );
  }
}

abstract class TypeOptionBuilder {
  Widget? get customWidget;
}

abstract class TypeOptionWidget extends StatelessWidget {
  const TypeOptionWidget({Key? key}) : super(key: key);
}

typedef TypeOptionData = Uint8List;
typedef TypeOptionDataCallback = void Function(TypeOptionData typeOptionData);

TypeOptionBuilder _makeTypeOptionBuild({
  required FieldType fieldType,
  required TypeOptionData typeOptionData,
  required TypeOptionDataCallback typeOptionDataCallback,
}) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionBuilder(typeOptionData);
    case FieldType.DateTime:
      return DateTypeOptionBuilder(typeOptionData);
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionBuilder(typeOptionData);
    case FieldType.Number:
      return NumberTypeOptionBuilder(typeOptionData, typeOptionDataCallback);
    case FieldType.RichText:
      return RichTextTypeOptionBuilder(typeOptionData);
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionBuilder(typeOptionData);
    default:
      throw UnimplementedError;
  }
}

class RichTextTypeOptionBuilder extends TypeOptionBuilder {
  RichTextTypeOption typeOption;

  RichTextTypeOptionBuilder(TypeOptionData typeOptionData) : typeOption = RichTextTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => null;
}

class DateTypeOptionBuilder extends TypeOptionBuilder {
  DateTypeOption typeOption;

  DateTypeOptionBuilder(TypeOptionData typeOptionData) : typeOption = DateTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => const DateTypeOptionWidget();
}

class DateTypeOptionWidget extends TypeOptionWidget {
  const DateTypeOptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DateTypeOptionBloc>(),
      child: Container(height: 80, color: Colors.red),
    );
  }
}

class CheckboxTypeOptionBuilder extends TypeOptionBuilder {
  CheckboxTypeOption typeOption;

  CheckboxTypeOptionBuilder(TypeOptionData typeOptionData) : typeOption = CheckboxTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => null;
}

class SingleSelectTypeOptionBuilder extends TypeOptionBuilder {
  SingleSelectTypeOption typeOption;

  SingleSelectTypeOptionBuilder(TypeOptionData typeOptionData)
      : typeOption = SingleSelectTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => const SingleSelectTypeOptionWidget();
}

class SingleSelectTypeOptionWidget extends TypeOptionWidget {
  const SingleSelectTypeOptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SelectionTypeOptionBloc>(),
      child: Container(height: 100, color: Colors.yellow),
    );
  }
}

class MultiSelectTypeOptionBuilder extends TypeOptionBuilder {
  MultiSelectTypeOption typeOption;

  MultiSelectTypeOptionBuilder(TypeOptionData typeOptionData)
      : typeOption = MultiSelectTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => const MultiSelectTypeOptionWidget();
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  const MultiSelectTypeOptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SelectionTypeOptionBloc>(),
      child: Container(height: 100, color: Colors.blue),
    );
  }
}
