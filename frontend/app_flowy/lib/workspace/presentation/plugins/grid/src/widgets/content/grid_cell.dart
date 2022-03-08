import 'package:app_flowy/workspace/application/grid/row_bloc.dart';
import 'package:app_flowy/workspace/presentation/home/menu/app/header/add_button.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/mouse_hover_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cell_decoration.dart';
// ignore: import_of_legacy_library_into_null_safe

/// The interface of base cell.
abstract class GridCellWidget extends StatelessWidget {
  final canSelect = true;

  const GridCellWidget({Key? key}) : super(key: key);
}

class GridTextCell extends GridCellWidget {
  late final TextEditingController _controller;

  GridTextCell(String content, {Key? key}) : super(key: key) {
    _controller = TextEditingController(text: content);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {},
      maxLines: 1,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        isDense: true,
      ),
    );
  }
}

class DateCell extends GridCellWidget {
  final String content;
  const DateCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class NumberCell extends GridCellWidget {
  final String content;
  const NumberCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class SingleSelectCell extends GridCellWidget {
  final String content;
  const SingleSelectCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class MultiSelectCell extends GridCellWidget {
  final String content;
  const MultiSelectCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class BlankCell extends GridCellWidget {
  const BlankCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class RowLeading extends StatelessWidget {
  final String rowId;
  const RowLeading({required this.rowId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      builder: (context, state) {
        if (state.isHighlight) {
          return Row(
            children: const [
              CreateRowButton(),
              DrawRowButton(),
            ],
          );
        }

        return const SizedBox.expand();
      },
    );
  }
}

class CreateRowButton extends StatelessWidget {
  const CreateRowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Tooltip(
      message: '',
      child: FlowyIconButton(
        hoverColor: theme.hover,
        width: 22,
        onPressed: () => context.read<RowBloc>().add(const RowEvent.createRow()),
        icon: svg("home/add"),
      ),
    );
  }
}

class DrawRowButton extends StatelessWidget {
  const DrawRowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
