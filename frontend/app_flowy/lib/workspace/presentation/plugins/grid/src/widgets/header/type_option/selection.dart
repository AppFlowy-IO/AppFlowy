import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/selection_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_tyep_switcher.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
