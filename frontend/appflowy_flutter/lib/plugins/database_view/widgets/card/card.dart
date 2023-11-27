import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/row/action.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_bloc.dart';
import 'card_cell_builder.dart';
import 'cells/card_cell.dart';
import 'container/accessory.dart';
import 'container/card_container.dart';

/// Edit a database row with card style widget
class RowCard<CustomCardData> extends StatefulWidget {
  final RowMetaPB rowMeta;
  final String viewId;
  final String? groupingFieldId;
  final String? groupId;

  /// Allows passing a custom card data object to the card. The card will be
  /// returned in the [CardCellBuilder] and can be used to build the card.
  final CustomCardData? cardData;
  final bool isEditing;
  final RowCache rowCache;

  /// The [CardCellBuilder] is used to build the card cells.
  final CardCellBuilder<CustomCardData> cellBuilder;

  /// Called when the user taps on the card.
  final void Function(BuildContext) openCard;

  /// Called when the user starts editing the card.
  final VoidCallback onStartEditing;

  /// Called when the user ends editing the card.
  final VoidCallback onEndEditing;

  /// The [RowCardRenderHook] is used to render the card's cell. Other than
  /// using the default cell builder. For example the [SelectOptionCardCell]
  final RowCardRenderHook<CustomCardData>? renderHook;

  final RowCardStyleConfiguration styleConfiguration;

  const RowCard({
    super.key,
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
    this.cardData,
    this.styleConfiguration = const RowCardStyleConfiguration(
      showAccessory: true,
    ),
    this.renderHook,
  });

  @override
  State<RowCard<CustomCardData>> createState() =>
      _RowCardState<CustomCardData>();
}

class _RowCardState<T> extends State<RowCard<T>> {
  final popoverController = PopoverController();
  late final CardBloc _cardBloc;
  late final EditableRowNotifier rowNotifier;
  AccessoryType? accessoryType;

  @override
  void initState() {
    super.initState();
    rowNotifier = EditableRowNotifier(isEditing: widget.isEditing);
    _cardBloc = CardBloc(
      viewId: widget.viewId,
      groupFieldId: widget.groupingFieldId,
      isEditing: widget.isEditing,
      rowMeta: widget.rowMeta,
      rowCache: widget.rowCache,
    )..add(const RowCardEvent.initial());

    rowNotifier.isEditing.addListener(() {
      if (!mounted) return;
      _cardBloc.add(RowCardEvent.setIsEditing(rowNotifier.isEditing.value));

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
      child: BlocBuilder<CardBloc, RowCardState>(
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
            // TODO(yijing): refactor it in mobile to display card in database view
            return RowCardContainer(
              buildAccessoryWhen: () => state.isEditing == false,
              accessories: const [],
              openAccessory: (p0) {},
              openCard: (context) => widget.openCard(context),
              child: _CardContent<T>(
                rowNotifier: rowNotifier,
                cellBuilder: widget.cellBuilder,
                styleConfiguration: widget.styleConfiguration,
                cells: state.cells,
                renderHook: widget.renderHook,
                cardData: widget.cardData,
              ),
            );
          }

          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            constraints: BoxConstraints.loose(const Size(140, 200)),
            direction: PopoverDirection.rightWithCenterAligned,
            popupBuilder: (popoverContext) {
              return RowActions(
                viewId: _cardBloc.viewId,
                rowId: _cardBloc.rowMeta.id,
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
              child: _CardContent<T>(
                rowNotifier: rowNotifier,
                cellBuilder: widget.cellBuilder,
                styleConfiguration: widget.styleConfiguration,
                cells: state.cells,
                renderHook: widget.renderHook,
                cardData: widget.cardData,
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

class _CardContent<CustomCardData> extends StatefulWidget {
  const _CardContent({
    super.key,
    required this.rowNotifier,
    required this.cellBuilder,
    required this.cells,
    required this.cardData,
    required this.styleConfiguration,
    this.renderHook,
  });

  final CardCellBuilder<CustomCardData> cellBuilder;
  final EditableRowNotifier rowNotifier;
  final List<DatabaseCellContext> cells;
  final RowCardRenderHook<CustomCardData>? renderHook;
  final CustomCardData? cardData;
  final RowCardStyleConfiguration styleConfiguration;

  @override
  State<_CardContent<CustomCardData>> createState() =>
      _CardContentState<CustomCardData>();
}

class _CardContentState<CustomCardData>
    extends State<_CardContent<CustomCardData>> {
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
            children: _makeCells(context, widget.cells),
          ),
        ),
      );
    }
    return Padding(
      padding: widget.styleConfiguration.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _makeCells(context, widget.cells),
      ),
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    List<DatabaseCellContext> cells,
  ) {
    final List<Widget> children = [];
    // Remove all the cell listeners.
    widget.rowNotifier.unbind();

    cells.asMap().forEach((int index, DatabaseCellContext cellContext) {
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
        key: cellContext.key(),
        padding: widget.styleConfiguration.cellPadding,
        child: widget.cellBuilder.buildCell(
          cellContext: cellContext,
          cellNotifier: cellNotifier,
          renderHook: widget.renderHook,
          cardData: widget.cardData,
          hasNotes: !cellContext.rowMeta.isDocumentEmpty,
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
    Key? key,
  }) : super(key: key);

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
