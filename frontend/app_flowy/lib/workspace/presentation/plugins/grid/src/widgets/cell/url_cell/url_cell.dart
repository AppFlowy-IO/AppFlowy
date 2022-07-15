import 'dart:async';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/grid/cell/url_cell_bloc.dart';
import 'package:app_flowy/workspace/presentation/home/toast.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/cell_accessory.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final GridCellControllerBuilder cellContorllerBuilder;
  late final GridURLCellStyle? cellStyle;
  GridURLCell({
    required this.cellContorllerBuilder,
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

  GridCellAccessory accessoryFromType(GridURLCellAccessoryType ty, GridCellAccessoryBuildContext buildContext) {
    switch (ty) {
      case GridURLCellAccessoryType.edit:
        final cellContext = cellContorllerBuilder.build() as GridURLCellController;
        return _EditURLAccessory(cellContext: cellContext, anchorContext: buildContext.anchorContext);

      case GridURLCellAccessoryType.copyURL:
        final cellContext = cellContorllerBuilder.build() as GridURLCellController;
        return _CopyURLAccessory(cellContext: cellContext);
    }
  }

  @override
  List<GridCellAccessory> Function(GridCellAccessoryBuildContext buildContext) get accessoryBuilder => (buildContext) {
        final List<GridCellAccessory> accessories = [];
        if (cellStyle != null) {
          accessories.addAll(cellStyle!.accessoryTypes.map((ty) {
            return accessoryFromType(ty, buildContext);
          }));
        }

        // If the accessories is empty then the default accessory will be GridURLCellAccessoryType.edit
        if (accessories.isEmpty) {
          accessories.add(accessoryFromType(GridURLCellAccessoryType.edit, buildContext));
        }

        return accessories;
      };
}

class _GridURLCellState extends GridCellState<GridURLCell> {
  late URLCellBloc _cellBloc;

  @override
  void initState() {
    final cellContext = widget.cellContorllerBuilder.build() as GridURLCellController;
    _cellBloc = URLCellBloc(cellContext: cellContext);
    _cellBloc.add(const URLCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<URLCellBloc, URLCellState>(
        builder: (context, state) {
          final richText = RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              text: state.content,
              style: TextStyle(
                color: theme.main2,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          );

          return SizedBox.expand(
              child: GestureDetector(
            child: Align(alignment: Alignment.centerLeft, child: richText),
            onTap: () async {
              final url = context.read<URLCellBloc>().state.url;
              await _openUrlOrEdit(url);
            },
          ));
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
    } else {
      final cellContext = widget.cellContorllerBuilder.build() as GridURLCellController;
      widget.onCellEditing.value = true;
      URLCellEditor.show(context, cellContext, () {
        widget.onCellEditing.value = false;
      });
    }
  }

  @override
  void requestBeginFocus() {
    _openUrlOrEdit(_cellBloc.state.url);
  }

  @override
  String? onCopy() => _cellBloc.state.content;

  @override
  void onInsert(String value) {
    _cellBloc.add(URLCellEvent.updateURL(value));
  }
}

class _EditURLAccessory extends StatelessWidget with GridCellAccessory {
  final GridURLCellController cellContext;
  final BuildContext anchorContext;
  const _EditURLAccessory({
    required this.cellContext,
    required this.anchorContext,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return svgWidget("editor/edit", color: theme.iconColor);
  }

  @override
  void onTap() {
    URLCellEditor.show(anchorContext, cellContext, () {});
  }
}

class _CopyURLAccessory extends StatelessWidget with GridCellAccessory {
  final GridURLCellController cellContext;
  const _CopyURLAccessory({required this.cellContext, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return svgWidget("editor/copy", color: theme.iconColor);
  }

  @override
  void onTap() {
    final content = cellContext.getCellData(loadIfNoCache: false)?.content ?? "";
    Clipboard.setData(ClipboardData(text: content));
    showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
  }
}
