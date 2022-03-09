import 'package:flutter/material.dart';

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
