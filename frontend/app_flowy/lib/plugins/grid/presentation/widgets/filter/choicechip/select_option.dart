import 'package:app_flowy/plugins/grid/application/filter/select_option_filter_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'choicechip.dart';

class SelectOptionFilterChoicechip extends StatefulWidget {
  final FilterInfo filterInfo;
  const SelectOptionFilterChoicechip({required this.filterInfo, Key? key})
      : super(key: key);

  @override
  State<SelectOptionFilterChoicechip> createState() =>
      _SelectOptionFilterChoicechipState();
}

class _SelectOptionFilterChoicechipState
    extends State<SelectOptionFilterChoicechip> {
  late SelectOptionFilterEditorBloc bloc;

  @override
  void initState() {
    bloc = SelectOptionFilterEditorBloc(filterInfo: widget.filterInfo)
      ..add(const SelectOpitonFilterEditorEvent.initial());
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<SelectOptionFilterEditorBloc,
          SelectOptionFilterEditorState>(
        builder: (blocContext, state) {
          return AppFlowyPopover(
            controller: PopoverController(),
            constraints: BoxConstraints.loose(const Size(200, 76)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (BuildContext context) {
              return Container();
            },
            child: ChoiceChipButton(
              filterInfo: widget.filterInfo,
              filterDesc: "",
            ),
          );
        },
      ),
    );
  }
}
