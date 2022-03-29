import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/single_select_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_tyep_switcher.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'option_pannel.dart';

class SingleSelectTypeOptionBuilder extends TypeOptionBuilder {
  final SingleSelectTypeOptionWidget _widget;

  SingleSelectTypeOptionBuilder(
    String fieldId,
    TypeOptionData typeOptionData,
    TypeOptionOperationDelegate delegate,
  ) : _widget = SingleSelectTypeOptionWidget(
          fieldId,
          SingleSelectTypeOption.fromBuffer(typeOptionData),
          delegate,
        );

  @override
  Widget? get customWidget => _widget;
}

class SingleSelectTypeOptionWidget extends TypeOptionWidget {
  final String fieldId;
  final SingleSelectTypeOption typeOption;
  final TypeOptionOperationDelegate delegate;
  const SingleSelectTypeOptionWidget(this.fieldId, this.typeOption, this.delegate, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SingleSelectTypeOptionBloc>(param1: typeOption, param2: fieldId),
      child: BlocConsumer<SingleSelectTypeOptionBloc, SingleSelectTypeOptionState>(
        listener: (context, state) => delegate.didUpdateTypeOptionData(state.typeOption.writeToBuffer()),
        builder: (context, state) {
          return OptionPannel(
            options: state.typeOption.options,
            beginEdit: () {
              delegate.hideOverlay(context);
            },
            createOptionCallback: (name) {
              context.read<SingleSelectTypeOptionBloc>().add(SingleSelectTypeOptionEvent.createOption(name));
            },
            updateOptionsCallback: (options) {
              context.read<SingleSelectTypeOptionBloc>().add(SingleSelectTypeOptionEvent.updateOptions(options));
            },
          );
        },
      ),
    );
  }
}
