import 'dart:async';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/cell/url_cell_bloc.dart';
import 'package:app_flowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../layout/sizes.dart';
import '../cell_accessory.dart';
import '../cell_builder.dart';
import 'cell_editor.dart';

class GridURLCellStyle extends GridCellStyle {
  String? placeholder;

  List<GridURLCellAccessoryType> accessoryTypes;

  GridURLCellStyle({
    this.placeholder,
    this.accessoryTypes = const [],
  });
}

enum GridURLCellAccessoryType {
  edit,
  copyURL,
}

class GridURLCell extends GridCellWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  late final GridURLCellStyle? cellStyle;
  GridURLCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as GridURLCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridCellState<GridURLCell> createState() => _GridURLCellState();

  GridCellAccessoryBuilder accessoryFromType(
      GridURLCellAccessoryType ty, GridCellAccessoryBuildContext buildContext) {
    switch (ty) {
      case GridURLCellAccessoryType.edit:
        return GridCellAccessoryBuilder(
          builder: (Key key) => _EditURLAccessory(
            key: key,
            anchorContext: buildContext.anchorContext,
            cellControllerBuilder: cellControllerBuilder,
          ),
        );

      case GridURLCellAccessoryType.copyURL:
        final cellContext =
            cellControllerBuilder.build() as GridURLCellController;
        return GridCellAccessoryBuilder(
          builder: (Key key) => _CopyURLAccessory(
            key: key,
            cellContext: cellContext,
          ),
        );
    }
  }

  @override
  List<GridCellAccessoryBuilder> Function(
          GridCellAccessoryBuildContext buildContext)
      get accessoryBuilder => (buildContext) {
            final List<GridCellAccessoryBuilder> accessories = [];
            if (cellStyle != null) {
              accessories.addAll(cellStyle!.accessoryTypes.map((ty) {
                return accessoryFromType(ty, buildContext);
              }));
            }

            // If the accessories is empty then the default accessory will be GridURLCellAccessoryType.edit
            if (accessories.isEmpty) {
              accessories.add(accessoryFromType(
                  GridURLCellAccessoryType.edit, buildContext));
            }

            return accessories;
          };
}

class _GridURLCellState extends GridCellState<GridURLCell> {
  final _popoverController = PopoverController();
  late URLCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridURLCellController;
    _cellBloc = URLCellBloc(cellController: cellController);
    _cellBloc.add(const URLCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<URLCellBloc, URLCellState>(
        builder: (context, state) {
          final richText = Padding(
            padding: GridSize.cellContentInsets,
            child: FlowyText.medium(
              state.content,
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          );

          return AppFlowyPopover(
            controller: _popoverController,
            constraints: BoxConstraints.loose(const Size(300, 160)),
            direction: PopoverDirection.bottomWithLeftAligned,
            triggerActions: PopoverTriggerFlags.none,
            offset: const Offset(0, 20),
            child: SizedBox.expand(
              child: GestureDetector(
                child: Align(alignment: Alignment.centerLeft, child: richText),
                onTap: () async {
                  final url = context.read<URLCellBloc>().state.url;
                  await _openUrlOrEdit(url);
                },
              ),
            ),
            popupBuilder: (BuildContext popoverContext) {
              return URLEditorPopover(
                cellController: widget.cellControllerBuilder.build()
                    as GridURLCellController,
              );
            },
            onClose: () {
              widget.onCellEditing.value = false;
            },
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  Future<void> _openUrlOrEdit(String url) async {
    final uri = Uri.parse(url);
    if (url.isNotEmpty && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void requestBeginFocus() {
    widget.onCellEditing.value = true;
    _popoverController.show();
  }

  @override
  String? onCopy() => _cellBloc.state.content;

  @override
  void onInsert(String value) {
    _cellBloc.add(URLCellEvent.updateURL(value));
  }
}

class _EditURLAccessory extends StatefulWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  final BuildContext anchorContext;
  const _EditURLAccessory({
    required this.cellControllerBuilder,
    required this.anchorContext,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EditURLAccessoryState();
}

class _EditURLAccessoryState extends State<_EditURLAccessory>
    with GridCellAccessoryState {
  late PopoverController _popoverController;

  @override
  void initState() {
    _popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(300, 160)),
      controller: _popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 20),
      child: svgWidget(
        "editor/edit",
        color: Theme.of(context).colorScheme.onSurface,
      ),
      popupBuilder: (BuildContext popoverContext) {
        return URLEditorPopover(
          cellController:
              widget.cellControllerBuilder.build() as GridURLCellController,
        );
      },
    );
  }

  @override
  void onTap() {
    _popoverController.show();
  }
}

class _CopyURLAccessory extends StatefulWidget {
  final GridURLCellController cellContext;
  const _CopyURLAccessory({required this.cellContext, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CopyURLAccessoryState();
}

class _CopyURLAccessoryState extends State<_CopyURLAccessory>
    with GridCellAccessoryState {
  @override
  Widget build(BuildContext context) {
    return svgWidget(
      "editor/copy",
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  @override
  void onTap() {
    final content =
        widget.cellContext.getCellData(loadIfNotExist: false)?.content ?? "";
    Clipboard.setData(ClipboardData(text: content));
    showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
  }
}
