import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/row/action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_bloc.dart';
import '../cell/card_cell_builder.dart';
import '../cell/card_cell_skeleton/card_cell.dart';
import 'container/accessory.dart';
import 'container/card_container.dart';

/// Edit a database row with card style widget
class RowCard extends StatefulWidget {
  final FieldController fieldController;
  final RowMetaPB rowMeta;
  final String viewId;
  final String? groupingFieldId;
  final String? groupId;

  final bool isEditing;
  final RowCache rowCache;

  /// The [CardCellBuilder] is used to build the card cells.
  final CardCellBuilder cellBuilder;

  /// Called when the user taps on the card.
  final void Function(BuildContext) openCard;

  /// Called when the user starts editing the card.
  final VoidCallback onStartEditing;

  /// Called when the user ends editing the card.
  final VoidCallback onEndEditing;

  final RowCardStyleConfiguration styleConfiguration;

  const RowCard({
    super.key,
    required this.fieldController,
    required this.rowMeta,
    required this.viewId,
    required this.isEditing,
    required this.rowCache,
    required this.cellBuilder,
    required this.openCard,
    required this.onStartEditing,
    required this.onEndEditing,
    this.groupingFieldId,
    this.groupId,
    this.styleConfiguration = const RowCardStyleConfiguration(
      showAccessory: true,
    ),
  });

  @override
  State<RowCard> createState() => _RowCardState();
}

class _RowCardState extends State<RowCard> {
  final popoverController = PopoverController();
  late final CardBloc _cardBloc;
  late final EditableRowNotifier rowNotifier;
  AccessoryType? accessoryType;

  @override
  void initState() {
    super.initState();
    rowNotifier = EditableRowNotifier(isEditing: widget.isEditing);
    _cardBloc = CardBloc(
      fieldController: widget.fieldController,
      viewId: widget.viewId,
      groupFieldId: widget.groupingFieldId,
      isEditing: widget.isEditing,
      rowMeta: widget.rowMeta,
      rowCache: widget.rowCache,
    )..add(const CardEvent.initial());

    rowNotifier.isEditing.addListener(() {
      if (!mounted) return;
      _cardBloc.add(CardEvent.setIsEditing(rowNotifier.isEditing.value));

      if (rowNotifier.isEditing.value) {
        widget.onStartEditing();
      } else {
        widget.onEndEditing();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cardBloc,
      child: BlocBuilder<CardBloc, CardState>(
        buildWhen: (previous, current) {
          // Rebuild when:
          // 1. If the length of the cells is not the same or isEditing changed
          if (previous.cells.length != current.cells.length ||
              previous.isEditing != current.isEditing) {
            return true;
          }

          // 2. the content of the cells changed
          return !listEquals(previous.cells, current.cells);
        },
        builder: (context, state) {
          if (PlatformExtension.isMobile) {
            return GestureDetector(
              child: MobileCardContent(
                rowMeta: state.rowMeta,
                cellBuilder: widget.cellBuilder,
                styleConfiguration: widget.styleConfiguration,
                cells: state.cells,
              ),
              onTap: () => widget.openCard(context),
            );
          }

          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            constraints: BoxConstraints.loose(const Size(140, 200)),
            direction: PopoverDirection.rightWithCenterAligned,
            popupBuilder: (_) {
              return RowActionMenu.board(
                viewId: _cardBloc.viewId,
                rowId: _cardBloc.rowId,
                groupId: widget.groupId,
              );
            },
            child: RowCardContainer(
              buildAccessoryWhen: () => state.isEditing == false,
              accessories: [
                if (widget.styleConfiguration.showAccessory) ...[
                  _CardEditOption(rowNotifier: rowNotifier),
                  const CardMoreOption(),
                ],
              ],
              openAccessory: _handleOpenAccessory,
              openCard: (context) => widget.openCard(context),
              child: _CardContent(
                rowMeta: state.rowMeta,
                rowNotifier: rowNotifier,
                cellBuilder: widget.cellBuilder,
                styleConfiguration: widget.styleConfiguration,
                cells: state.cells,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleOpenAccessory(AccessoryType newAccessoryType) {
    accessoryType = newAccessoryType;
    switch (newAccessoryType) {
      case AccessoryType.edit:
        break;
      case AccessoryType.more:
        popoverController.show();
        break;
    }
  }

  @override
  Future<void> dispose() async {
    rowNotifier.dispose();
    _cardBloc.close();
    super.dispose();
  }
}

class _CardContent extends StatefulWidget {
  const _CardContent({
    required this.rowMeta,
    required this.rowNotifier,
    required this.cellBuilder,
    required this.cells,
    required this.styleConfiguration,
  });

  final RowMetaPB rowMeta;
  final EditableRowNotifier rowNotifier;
  final CardCellBuilder cellBuilder;
  final List<CellContext> cells;
  final RowCardStyleConfiguration styleConfiguration;

  @override
  State<_CardContent> createState() => _CardContentState();
}

class _CardContentState extends State<_CardContent> {
  final List<EditableCardNotifier> _notifiers = [];

  @override
  void dispose() {
    for (final element in _notifiers) {
      element.dispose();
    }
    _notifiers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.styleConfiguration.hoverStyle != null) {
      return FlowyHover(
        style: widget.styleConfiguration.hoverStyle,
        buildWhenOnHover: () => !widget.rowNotifier.isEditing.value,
        child: Padding(
          padding: widget.styleConfiguration.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _makeCells(context, widget.rowMeta, widget.cells),
          ),
        ),
      );
    }
    return Padding(
      padding: widget.styleConfiguration.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _makeCells(context, widget.rowMeta, widget.cells),
      ),
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    RowMetaPB rowMeta,
    List<CellContext> cells,
  ) {
    final List<Widget> children = [];
    // Remove all the cell listeners.
    widget.rowNotifier.unbind();

    cells.asMap().forEach((int index, CellContext cellContext) {
      final isEditing = index == 0 ? widget.rowNotifier.isEditing.value : false;
      final cellNotifier = EditableCardNotifier(isEditing: isEditing);

      if (index == 0) {
        // Only use the first cell to receive user's input when click the edit
        // button
        widget.rowNotifier.bindCell(cellContext, cellNotifier);
      } else {
        _notifiers.add(cellNotifier);
      }

      final child = Padding(
        padding: widget.styleConfiguration.cellPadding,
        child: widget.cellBuilder.build(
          cellContext: cellContext,
          cellNotifier: cellNotifier,
          hasNotes: !rowMeta.isDocumentEmpty,
        ),
      );

      children.add(child);
    });
    return children;
  }
}

class CardMoreOption extends StatelessWidget with CardAccessory {
  const CardMoreOption({super.key});

  @override
  AccessoryType get type => AccessoryType.more;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: FlowySvg(
        FlowySvgs.three_dots_s,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}

class _CardEditOption extends StatelessWidget with CardAccessory {
  final EditableRowNotifier rowNotifier;
  const _CardEditOption({
    required this.rowNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: FlowySvg(
        FlowySvgs.edit_s,
        color: Theme.of(context).hintColor,
      ),
    );
  }

  @override
  void onTap(BuildContext context) => rowNotifier.becomeFirstResponder();

  @override
  AccessoryType get type => AccessoryType.edit;
}

class RowCardStyleConfiguration {
  final bool showAccessory;
  final EdgeInsets cellPadding;
  final EdgeInsets cardPadding;
  final HoverStyle? hoverStyle;

  const RowCardStyleConfiguration({
    this.showAccessory = true,
    this.cellPadding = EdgeInsets.zero,
    this.cardPadding = const EdgeInsets.all(8),
    this.hoverStyle,
  });
}
