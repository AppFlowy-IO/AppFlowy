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
    TypeOptionOverlayDelegate overlayDelegate,
    TypeOptionDataDelegate dataDelegate,
  ) : _widget = SingleSelectTypeOptionWidget(
          fieldId: fieldId,
          typeOption: SingleSelectTypeOption.fromBuffer(typeOptionData),
          dataDelegate: dataDelegate,
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? get customWidget => _widget;
}

class SingleSelectTypeOptionWidget extends TypeOptionWidget {
  final String fieldId;
  final SingleSelectTypeOption typeOption;
  final TypeOptionOverlayDelegate overlayDelegate;
  final TypeOptionDataDelegate dataDelegate;
  const SingleSelectTypeOptionWidget({
    required this.fieldId,
    required this.typeOption,
    required this.dataDelegate,
    required this.overlayDelegate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SingleSelectTypeOptionBloc>(param1: typeOption, param2: fieldId),
      child: BlocConsumer<SingleSelectTypeOptionBloc, SingleSelectTypeOptionState>(
        listener: (context, state) {
          dataDelegate.didUpdateTypeOptionData(state.typeOption.writeToBuffer());
        },
        builder: (context, state) {
          return OptionPannel(
            options: state.typeOption.options,
            beginEdit: () {
              overlayDelegate.hideOverlay(context);
            },
            createOptionCallback: (name) {
              context.read<SingleSelectTypeOptionBloc>().add(SingleSelectTypeOptionEvent.createOption(name));
            },
            updateOptionCallback: (updateOption) {
              context.read<SingleSelectTypeOptionBloc>().add(SingleSelectTypeOptionEvent.updateOption(updateOption));
            },
            deleteOptionCallback: (deleteOption) {
              context.read<SingleSelectTypeOptionBloc>().add(SingleSelectTypeOptionEvent.deleteOption(deleteOption));
            },
            overlayDelegate: overlayDelegate,
            key: ValueKey(state.typeOption.hashCode),
          );
        },
      ),
    );
  }
}
