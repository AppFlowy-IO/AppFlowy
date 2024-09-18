import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/filter/text_filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/text.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../filter_info.dart';
import 'choicechip.dart';

class URLFilterChoiceChip extends StatelessWidget {
  const URLFilterChoiceChip({required this.filterInfo, super.key});

  final FilterInfo filterInfo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TextFilterBloc(
        filterInfo: filterInfo,
        fieldType: FieldType.URL,
      ),
      child: Builder(
        builder: (context) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(200, 76)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (popoverContext) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<TextFilterBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<FilterEditorBloc>(),
                  ),
                ],
                child: const TextFilterEditor(),
              );
            },
            child: BlocBuilder<TextFilterBloc, TextFilterState>(
              builder: (context, state) {
                return ChoiceChipButton(
                  filterInfo: filterInfo,
                  filterDesc: _makeFilterDesc(state),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _makeFilterDesc(TextFilterState state) {
    String filterDesc = state.filter.condition.choicechipPrefix;
    if (state.filter.condition == TextFilterConditionPB.TextIsEmpty ||
        state.filter.condition == TextFilterConditionPB.TextIsNotEmpty) {
      return filterDesc;
    }

    if (state.filter.content.isNotEmpty) {
      filterDesc += " ${state.filter.content}";
    }

    return filterDesc;
  }
}
