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
  final PopoverController _popover = PopoverController();
  late final DateCellController _cellController;
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    _cellController =
        widget.cellControllerBuilder.build() as DateCellController;
    _cellBloc = DateCellBloc(cellController: _cellController)
      ..add(const DateCellEvent.initial());
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
                child: FlowyText.medium(
                  text,
                  color: color,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              popupBuilder: (BuildContext popoverContent) {
                return DateCellEditor(
                  cellController: _cellController,
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
                    controller: _cellController,
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
                child: FlowyText.regular(
                  text,
                  fontSize: 16,
                  color: color,
                  maxLines: null,
                ),
              ),
            );
          } else {
            return FlowyButton(
              radius: BorderRadius.zero,
              hoverColor: Colors.transparent,
              margin: EdgeInsets.zero,
              text: Align(
                alignment: alignment,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: FlowyText(
                    text,
                    color: color,
                    fontSize: 15,
                    maxLines: 1,
                  ),
                ),
              ),
              onTap: () {
                showMobileBottomSheet(
                  context,
                  padding: EdgeInsets.zero,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  builder: (context) {
                    return MobileDateCellEditScreen(
                      controller: _cellController,
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
    _cellController.dispose();
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
