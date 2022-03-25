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
import 'package:flowy_sdk/protobuf/flowy-grid/number_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef SelectFieldCallback = void Function(FieldType);

class FieldTypeSwitcher extends StatelessWidget {
  final EditFieldContext editContext;

  const FieldTypeSwitcher({
    required this.editContext,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SwitchFieldTypeBloc>(param1: editContext),
      child: BlocBuilder<SwitchFieldTypeBloc, SwitchFieldTypeState>(
        builder: (context, state) {
          List<Widget> children = [
            _switchFieldTypeButton(context, state.field),
          ];

          final builder = _makeTypeOptionBuild(
            state.field.fieldType,
            state.typeOptionData,
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
  Uint8List? get typeOptionData;
  Widget? get customWidget;
}

abstract class TypeOptionWidget extends StatelessWidget {
  const TypeOptionWidget({Key? key}) : super(key: key);
}

TypeOptionBuilder _makeTypeOptionBuild(FieldType fieldType, Uint8List typeOptionData) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionBuilder(typeOptionData);
    case FieldType.DateTime:
      return DateTypeOptionBuilder(typeOptionData);
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionBuilder(typeOptionData);
    case FieldType.Number:
      return NumberTypeOptionBuilder(typeOptionData);
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

  RichTextTypeOptionBuilder(Uint8List typeOptionData) : typeOption = RichTextTypeOption.fromBuffer(typeOptionData);

  @override
  Uint8List? get typeOptionData => typeOption.writeToBuffer();

  @override
  Widget? get customWidget => null;
}

class NumberTypeOptionBuilder extends TypeOptionBuilder {
  NumberTypeOption typeOption;

  NumberTypeOptionBuilder(Uint8List typeOptionData) : typeOption = NumberTypeOption.fromBuffer(typeOptionData);

  @override
  Uint8List? get typeOptionData => typeOption.writeToBuffer();

  @override
  Widget? get customWidget => const NumberTypeOptionWidget();
}

class NumberTypeOptionWidget extends TypeOptionWidget {
  const NumberTypeOptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NumberTypeOptionBloc>(),
      child: Container(),
    );
  }
}

class DateTypeOptionBuilder extends TypeOptionBuilder {
  DateTypeOption typeOption;

  DateTypeOptionBuilder(Uint8List typeOptionData) : typeOption = DateTypeOption.fromBuffer(typeOptionData);

  @override
  Uint8List? get typeOptionData => typeOption.writeToBuffer();

  @override
  Widget? get customWidget => const DateTypeOptionWidget();
}

class DateTypeOptionWidget extends TypeOptionWidget {
  const DateTypeOptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DateTypeOptionBloc>(),
      child: Container(),
    );
  }
}

class CheckboxTypeOptionBuilder extends TypeOptionBuilder {
  CheckboxTypeOption typeOption;

  CheckboxTypeOptionBuilder(Uint8List typeOptionData) : typeOption = CheckboxTypeOption.fromBuffer(typeOptionData);

  @override
  Uint8List? get typeOptionData => throw UnimplementedError();

  @override
  Widget? get customWidget => null;
}

class SingleSelectTypeOptionBuilder extends TypeOptionBuilder {
  SingleSelectTypeOption typeOption;

  SingleSelectTypeOptionBuilder(Uint8List typeOptionData)
      : typeOption = SingleSelectTypeOption.fromBuffer(typeOptionData);

  @override
  Uint8List? get typeOptionData => typeOption.writeToBuffer();

  @override
  Widget? get customWidget => const SingleSelectTypeOptionWidget();
}

class SingleSelectTypeOptionWidget extends TypeOptionWidget {
  const SingleSelectTypeOptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SelectionTypeOptionBloc>(),
      child: Container(),
    );
  }
}

class MultiSelectTypeOptionBuilder extends TypeOptionBuilder {
  MultiSelectTypeOption typeOption;

  MultiSelectTypeOptionBuilder(Uint8List typeOptionData)
      : typeOption = MultiSelectTypeOption.fromBuffer(typeOptionData);

  @override
  Uint8List? get typeOptionData => typeOption.writeToBuffer();

  @override
  Widget? get customWidget => const MultiSelectTypeOptionWidget();
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  const MultiSelectTypeOptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SelectionTypeOptionBloc>(),
      child: Container(),
    );
  }
}
