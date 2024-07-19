import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/time_cell_editor.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/time_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra/size.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import '../editable_cell_skeleton/time.dart';

class DesktopGridTimeCellSkin extends IEditableTimeCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TimeCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    PopoverController popoverController,
  ) {
    return AppFlowyPopover(
      margin: EdgeInsets.zero,
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(360, 400)),
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      skipTraversal: true,
      popupBuilder: (BuildContext popoverContext) {
        return BlocProvider.value(
          value: bloc,
          child: TimeCellEditor(cellController: bloc.cellController),
        );
      },
      onClose: () => cellContainerNotifier.isFocus = false,
      child: _TimeCellView(
        popoverController: popoverController,
        textEditingController: textEditingController,
        focusNode: focusNode,
      ),
    );
  }
}

class _TimeCellView extends StatefulWidget {
  const _TimeCellView({
    required this.popoverController,
    required this.textEditingController,
    required this.focusNode,
  });

  final PopoverController popoverController;
  final TextEditingController textEditingController;
  final FocusNode focusNode;

  @override
  State<_TimeCellView> createState() => _TimeCellViewState();
}

class _TimeCellViewState extends State<_TimeCellView> {
  bool isHover = false;
  TimePrecisionPB? precision;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeCellState = context.watch<TimeCellBloc>().state;

    if (timeCellState.timeType == TimeTypePB.PlainTime) {
      timer?.cancel();

      return _TimeTextView(
        textEditingController: widget.textEditingController,
        focusNode: widget.focusNode,
        readOnly: false,
        wrap: timeCellState.wrap,
        onTap: () => {},
      );
    }

    final isTracking = timeCellState.isTracking;
    if (isTracking && _shouldCreateTimer(timeCellState.precision)) {
      precision = timeCellState.precision;
      final duration = precision == TimePrecisionPB.Minutes ? 60 : 1;

      timer?.cancel();
      timer = Timer.periodic(
        Duration(seconds: duration),
        (Timer t) => context
            .read<TimeCellBloc>()
            .cellController
            .getCellData(forceLoad: true),
      );
    } else if (!isTracking) {
      timer?.cancel();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          _TimeTextView(
            textEditingController: widget.textEditingController,
            focusNode: widget.focusNode,
            readOnly: true,
            wrap: timeCellState.wrap,
            onTap: widget.popoverController.show,
          ),
          if (isHover || isTracking)
            _TimeTrackButton(
              focusNode: widget.focusNode,
              isTracking: isTracking,
            ).positioned(right: GridSize.cellContentInsets.right),
        ],
      ),
    );
  }

  bool _shouldCreateTimer(currentPrecision) =>
      !(timer?.isActive ?? false) || currentPrecision != precision;
}

class _TimeTextView extends StatelessWidget {
  const _TimeTextView({
    required this.textEditingController,
    required this.focusNode,
    required this.readOnly,
    required this.wrap,
    required this.onTap,
  });

  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final bool readOnly;
  final bool wrap;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextField(
        controller: textEditingController,
        readOnly: readOnly,
        onTap: onTap,
        focusNode: focusNode,
        onEditingComplete: () => focusNode.unfocus(),
        onSubmitted: (_) {
          focusNode.unfocus();
        },
        maxLines: wrap ? null : 1,
        style: Theme.of(context).textTheme.bodyMedium,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          contentPadding: GridSize.cellContentInsets,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _TimeTrackButton extends StatelessWidget {
  const _TimeTrackButton({
    required this.focusNode,
    required this.isTracking,
  });

  final FocusNode focusNode;
  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: isTracking
          ? LocaleKeys.grid_field_timeStopTracking.tr()
          : LocaleKeys.grid_field_timeStartTracking.tr(),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).dividerColor),
          ),
          borderRadius: Corners.s6Border,
        ),
        child: FlowyIconButton(
          onPressed: () {
            if (isTracking) {
              context
                  .read<TimeCellBloc>()
                  .add(const TimeCellEvent.stopTracking());
            } else {
              context
                  .read<TimeCellBloc>()
                  .add(const TimeCellEvent.startTracking());
            }

            focusNode.unfocus();
          },
          icon: Center(
            child: isTracking
                ? Icon(
                    Icons.pause,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
        ),
      ),
    );
  }
}
