import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/row/action.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/card/card_bloc.dart';
import 'package:appflowy/plugins/database/widgets/card/container/accessory.dart';
import 'package:appflowy/plugins/database/widgets/card/container/card_container.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GalleryCard extends StatefulWidget {
  const GalleryCard({
    super.key,
    required this.viewId,
    required this.controller,
    required this.rowMeta,
    required this.rowCache,
    required this.onTap,
    required this.cellBuilder,
    required this.styleConfiguration,
    this.onShiftTap,
    this.userProfile,
  });

  final String viewId;
  final FieldController controller;
  final RowMetaPB rowMeta;
  final RowCache rowCache;

  final CardCellBuilder cellBuilder;
  final RowCardStyleConfiguration styleConfiguration;

  final void Function(BuildContext context) onTap;
  final void Function(BuildContext context)? onShiftTap;

  final UserProfilePB? userProfile;

  @override
  State<GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<GalleryCard> {
  final popoverController = PopoverController();
  late final CardBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CardBloc(
      viewId: widget.viewId,
      fieldController: widget.controller,
      rowController: RowController(
        viewId: widget.viewId,
        rowMeta: widget.rowMeta,
        rowCache: widget.rowCache,
      ),
    );
  }

  @override
  void dispose() {
    bloc.close();
    popoverController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessories = widget.styleConfiguration.showAccessory
        ? const <CardAccessory>[MoreCardOptionsAccessory()]
        : null;

    return BlocProvider.value(
      value: bloc..add(const CardEvent.initial()),
      child: Builder(
        builder: (context) {
          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            constraints: BoxConstraints.loose(const Size(140, 200)),
            offset: const Offset(5, 0),
            popupBuilder: (_) => RowActionMenu.gallery(
              viewId: widget.viewId,
              rowId: bloc.rowController.rowId,
            ),
            child: RowCardContainer(
              accessories: accessories ?? [],
              openAccessory: (_) => popoverController.show(),
              onTap: (_) => widget.onTap(context),
              child: Container(
                clipBehavior: Clip.antiAlias,
                constraints: const BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4,
                      color: const Color(0xFF1F2329).withOpacity(0.02),
                    ),
                    BoxShadow(
                      blurRadius: 4,
                      spreadRadius: -2,
                      color: const Color(0xFF1F2329).withOpacity(0.02),
                    ),
                  ],
                ),
                child: BlocBuilder<CardBloc, CardState>(
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CardCover(
                          cover: state.rowMeta.cover,
                          userProfile: widget.userProfile,
                          showDefaultCover: true,
                        ),
                        Padding(
                          padding: widget.styleConfiguration.cardPadding,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _makeCells(
                              context,
                              state.rowMeta,
                              state.cells,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    RowMetaPB rowMeta,
    List<CellMeta> cells,
  ) {
    return cells
        .mapIndexed(
          (int index, CellMeta cellMeta) => CardContentCell(
            cellBuilder: widget.cellBuilder,
            cellMeta: cellMeta,
            rowMeta: rowMeta,
            isTitle: index == 0,
            styleMap: widget.styleConfiguration.cellStyleMap,
          ),
        )
        .toList();
  }
}
