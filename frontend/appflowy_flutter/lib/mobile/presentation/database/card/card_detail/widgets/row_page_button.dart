import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OpenRowPageButton extends StatefulWidget {
  const OpenRowPageButton({
    super.key,
    required this.documentId,
    required this.databaseController,
    required this.cellContext,
  });

  final String documentId;

  final DatabaseController databaseController;
  final CellContext cellContext;

  @override
  State<OpenRowPageButton> createState() => _OpenRowPageButtonState();
}

class _OpenRowPageButtonState extends State<OpenRowPageButton> {
  late final cellBloc = TextCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  );

  ViewPB? view;

  @override
  void initState() {
    super.initState();

    _preloadView(context, createDocumentIfMissed: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextCellBloc, TextCellState>(
      bloc: cellBloc,
      builder: (context, state) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            maxHeight: GridSize.buttonHeight,
          ),
          child: TextButton.icon(
            style: Theme.of(context).textButtonTheme.style?.copyWith(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  overlayColor: WidgetStateProperty.all<Color>(
                    Theme.of(context).hoverColor,
                  ),
                  alignment: AlignmentDirectional.centerStart,
                  splashFactory: NoSplash.splashFactory,
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
            label: FlowyText.medium(
              LocaleKeys.grid_field_openRowDocument.tr(),
              fontSize: 15,
            ),
            icon: const Padding(
              padding: EdgeInsets.all(4.0),
              child: FlowySvg(
                FlowySvgs.full_view_s,
                size: Size.square(16.0),
              ),
            ),
            onPressed: () {
              final name = state.content;
              _openRowPage(context, name);
            },
          ),
        );
      },
    );
  }

  Future<void> _openRowPage(BuildContext context, String fieldName) async {
    Log.info('Open row page(${widget.documentId})');

    if (view == null) {
      showToastNotification(context, message: 'Failed to open row page');
      // reload the view again
      unawaited(_preloadView(context));
      Log.error('Failed to open row page(${widget.documentId})');
      return;
    }

    if (context.mounted) {
      // the document in row is an orphan document, so we don't add it to recent
      await context.pushView(
        view!,
        addInRecent: false,
        showMoreButton: false,
        fixedTitle: fieldName,
      );
    }
  }

  // preload view to reduce the time to open the view
  Future<void> _preloadView(
    BuildContext context, {
    bool createDocumentIfMissed = false,
  }) async {
    Log.info('Preload row page(${widget.documentId})');
    final result = await ViewBackendService.getView(widget.documentId);
    view = result.fold((s) => s, (f) => null);

    if (view == null && createDocumentIfMissed) {
      // create view if not exists
      Log.info('Create row page(${widget.documentId})');
      final result = await ViewBackendService.createOrphanView(
        name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
        viewId: widget.documentId,
        layoutType: ViewLayoutPB.Document,
      );
      view = result.fold((s) => s, (f) => null);
    }
  }
}
