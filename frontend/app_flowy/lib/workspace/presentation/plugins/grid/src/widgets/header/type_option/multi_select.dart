import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/multi_select_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_switcher.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'option_pannel.dart';

class MultiSelectTypeOptionBuilder extends TypeOptionBuilder {
  final MultiSelectTypeOptionWidget _widget;

  MultiSelectTypeOptionBuilder(
    String fieldId,
    TypeOptionData typeOptionData,
    TypeOptionOverlayDelegate overlayDelegate,
    TypeOptionDataDelegate dataDelegate,
  ) : _widget = MultiSelectTypeOptionWidget(
          fieldId: fieldId,
          typeOption: MultiSelectTypeOption.fromBuffer(typeOptionData),
          overlayDelegate: overlayDelegate,
          dataDelegate: dataDelegate,
        );

  @override
  Widget? get customWidget => _widget;
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  final String fieldId;
  final MultiSelectTypeOption typeOption;
  final TypeOptionOverlayDelegate overlayDelegate;
  final TypeOptionDataDelegate dataDelegate;
  const MultiSelectTypeOptionWidget({
    required this.fieldId,
    required this.typeOption,
    required this.overlayDelegate,
    required this.dataDelegate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MultiSelectTypeOptionBloc>(param1: typeOption, param2: fieldId),
      child: BlocConsumer<MultiSelectTypeOptionBloc, MultiSelectTypeOptionState>(
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
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.createOption(name));
            },
            updateOptionCallback: (updateOption) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.updateOption(updateOption));
            },
            deleteOptionCallback: (deleteOption) {
              context.read<MultiSelectTypeOptionBloc>().add(MultiSelectTypeOptionEvent.deleteOption(deleteOption));
            },
            overlayDelegate: overlayDelegate,
            key: ValueKey(state.typeOption.hashCode),
          );
        },
      ),
    );
  }
}
