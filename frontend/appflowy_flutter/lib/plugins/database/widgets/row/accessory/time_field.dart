import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import 'cell_accessory.dart';
import '../../../application/cell/bloc/time_cell_editor_bloc.dart';

class TimeFieldAccessory extends StatefulWidget {
  const TimeFieldAccessory({
    super.key,
    required this.isCellEditing,
  });

  final bool isCellEditing;

  @override
  State<StatefulWidget> createState() => _TimeFieldAccessoryState();
}

class _TimeFieldAccessoryState extends State<TimeFieldAccessory>
    with GridCellAccessoryState {
  bool isTracking = false;

  @override
  Widget build(BuildContext context) {
    isTracking = context.watch<TimeCellEditorBloc>().state.isTracking;

    return FlowyHover(
      style: HoverStyle(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        backgroundColor: Theme.of(context).cardColor,
      ),
      builder: (_, onHover) {
        return FlowyTooltip(
          message: isTracking
              ? LocaleKeys.grid_field_timeStartTracking.tr()
              : LocaleKeys.grid_field_timeStopTracking.tr(),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: Theme.of(context).dividerColor),
              ),
              borderRadius: Corners.s6Border,
            ),
            child: Center(
              child: FlowySvg(
                isTracking ? FlowySvgs.timer_finish_s : FlowySvgs.timer_start_s,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void onTap() {
    if (isTracking) {
      context
          .read<TimeCellEditorBloc>()
          .add(const TimeCellEditorEvent.stopTracking());
    } else {
      context
          .read<TimeCellEditorBloc>()
          .add(const TimeCellEditorEvent.startTracking());
    }
  }

  @override
  bool enable() => !widget.isCellEditing;
}
