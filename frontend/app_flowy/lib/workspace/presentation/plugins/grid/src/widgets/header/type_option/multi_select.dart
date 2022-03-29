import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/multi_select_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_tyep_switcher.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'option_pannel.dart';

class MultiSelectTypeOptionBuilder extends TypeOptionBuilder {
  MultiSelectTypeOption typeOption;
  TypeOptionOperationDelegate delegate;

  MultiSelectTypeOptionBuilder(TypeOptionData typeOptionData, this.delegate)
      : typeOption = MultiSelectTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => MultiSelectTypeOptionWidget(typeOption, delegate);
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  final MultiSelectTypeOption typeOption;
  final TypeOptionOperationDelegate delegate;
  const MultiSelectTypeOptionWidget(this.typeOption, this.delegate, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MultiSelectTypeOptionBloc>(param1: typeOption),
      child: BlocBuilder<MultiSelectTypeOptionBloc, MultiSelectTypeOptionState>(
        builder: (context, state) {
          return OptionPannel(
            options: state.typeOption.options,
            beginEdit: () {
              delegate.hideOverlay(context);
            },
            createOptionCallback: (name) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.createOption(name));
            },
            updateOptionsCallback: (options) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.updateOptions(options));
            },
          );
        },
      ),
    );
  }
}
