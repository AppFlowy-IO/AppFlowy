import 'dart:async';
import 'package:app_flowy/workspace/application/grid/cell/url_cell_bloc.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cell_builder.dart';
import 'cell_editor.dart';

class GridURLCellStyle extends GridCellStyle {
  String? placeholder;

  GridURLCellStyle({
    this.placeholder,
  });
}

class GridURLCell extends StatefulWidget with GridCellWidget {
  final GridCellContextBuilder cellContextBuilder;
  late final GridURLCellStyle? cellStyle;
  GridURLCell({
    required this.cellContextBuilder,
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
  State<GridURLCell> createState() => _GridURLCellState();
}

class _GridURLCellState extends State<GridURLCell> {
  late URLCellBloc _cellBloc;

  @override
  void initState() {
    final cellContext = widget.cellContextBuilder.build() as GridURLCellContext;
    _cellBloc = URLCellBloc(cellContext: cellContext);
    _cellBloc.add(const URLCellEvent.initial());
    _listenRequestFocus(context);
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
              recognizer: _tapGesture(context),
            ),
          );

          return CellEnterRegion(
            child: Align(alignment: Alignment.centerLeft, child: richText),
            expander: _EditCellIndicator(onTap: () {}),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    widget.requestFocus.removeAllListener();
    _cellBloc.close();
    super.dispose();
  }

  TapGestureRecognizer _tapGesture(BuildContext context) {
    final gesture = TapGestureRecognizer();
    gesture.onTap = () async {
      final url = context.read<URLCellBloc>().state.url;
      await _openUrlOrEdit(url);
    };
    return gesture;
  }

  Future<void> _openUrlOrEdit(String url) async {
    final uri = Uri.parse(url);
    if (url.isNotEmpty && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final cellContext = widget.cellContextBuilder.build() as GridURLCellContext;
      URLCellEditor.show(context, cellContext);
    }
  }

  void _listenRequestFocus(BuildContext context) {
    widget.requestFocus.addListener(() {
      _openUrlOrEdit(_cellBloc.state.url);
    });
  }
}

class _EditCellIndicator extends StatelessWidget {
  final VoidCallback onTap;
  const _EditCellIndicator({required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      width: 26,
      onPressed: onTap,
      hoverColor: theme.hover,
      radius: BorderRadius.circular(4),
      iconPadding: const EdgeInsets.all(5),
      icon: svgWidget("editor/edit", color: theme.iconColor),
    );
  }
}
