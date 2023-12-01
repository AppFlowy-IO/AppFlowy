import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/date_picker/mobile_date_picker_screen.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';
import 'date_cell_bloc.dart';
import 'date_editor.dart';

class DateCellStyle extends GridCellStyle {
  String placeholder;
  Alignment alignment;
  EdgeInsets? cellPadding;
  final bool useRoundedBorder;

  DateCellStyle({
    this.placeholder = "",
    this.alignment = Alignment.centerLeft,
    this.cellPadding,
    this.useRoundedBorder = false,
  });
}

class GridDateCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final DateCellStyle cellStyle;

  GridDateCell({
    super.key,
    GridCellStyle? style,
    required this.cellControllerBuilder,
  }) {
    if (style != null) {
      cellStyle = (style as DateCellStyle);
    } else {
      cellStyle = DateCellStyle();
    }
  }

  @override
  GridCellState<GridDateCell> createState() => _DateCellState();
}

class _DateCellState extends GridCellState<GridDateCell> {
  late PopoverController _popover;
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    _popover = PopoverController();
    final cellController =
        widget.cellControllerBuilder.build() as DateCellController;
    _cellBloc = DateCellBloc(cellController: cellController)
      ..add(const DateCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
        builder: (context, state) {
          final text = state.dateStr.isEmpty
              ? widget.cellStyle.placeholder
              : state.dateStr;
          final color =
              state.dateStr.isEmpty ? Theme.of(context).hintColor : null;
          final padding =
              widget.cellStyle.cellPadding ?? GridSize.cellContentInsets;
          final alignment = widget.cellStyle.alignment;

          if (PlatformExtension.isDesktopOrWeb) {
            return AppFlowyPopover(
              controller: _popover,
              triggerActions: PopoverTriggerFlags.none,
              direction: PopoverDirection.bottomWithLeftAligned,
              constraints: BoxConstraints.loose(const Size(260, 620)),
              margin: EdgeInsets.zero,
              child: Container(
                alignment: alignment,
                padding: padding,
                child: FlowyText.medium(text, color: color),
              ),
              popupBuilder: (BuildContext popoverContent) {
                return DateCellEditor(
                  cellController: widget.cellControllerBuilder.build()
                      as DateCellController,
                  onDismissed: () =>
                      widget.cellContainerNotifier.isFocus = false,
                );
              },
              onClose: () {
                widget.cellContainerNotifier.isFocus = false;
              },
            );
          } else if (widget.cellStyle.useRoundedBorder) {
            return InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onTap: () => showMobileBottomSheet(
                context,
                padding: EdgeInsets.zero,
                builder: (context) {
                  return MobileDateCellEditScreen(
                    controller: widget.cellControllerBuilder.build()
                        as DateCellController,
                    showAsFullScreen: false,
                  );
                },
              ),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: double.infinity,
                ),
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                padding: padding,
                child: Row(
                  children: [
                    Expanded(
                      child: FlowyText.regular(
                        text,
                        fontSize: 16,
                        color: color,
                        maxLines: null,
                      ),
                    ),
                    const HSpace(6),
                    const RotatedBox(
                      quarterTurns: 3,
                      child: Icon(Icons.chevron_left),
                    ),
                    const HSpace(2),
                  ],
                ),
              ),
            );
          } else {
            return FlowyButton(
              text: Container(
                alignment: alignment,
                padding: padding,
                child: FlowyText.medium(text, color: color),
              ),
              onTap: () {
                showMobileBottomSheet(
                  context,
                  padding: EdgeInsets.zero,
                  builder: (context) {
                    return MobileDateCellEditScreen(
                      controller: widget.cellControllerBuilder.build()
                          as DateCellController,
                      showAsFullScreen: false,
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  void requestBeginFocus() {
    _popover.show();
    widget.cellContainerNotifier.isFocus = true;
  }

  @override
  String? onCopy() => _cellBloc.state.dateStr;
}
