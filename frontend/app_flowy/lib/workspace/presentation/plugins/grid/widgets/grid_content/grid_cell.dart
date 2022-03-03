import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe

/// The interface of base cell.
abstract class GridCell extends StatelessWidget {
  final canSelect = true;

  const GridCell({Key? key}) : super(key: key);
}

class GridTextCell extends GridCell {
  final String content;
  const GridTextCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class DateCell extends GridCell {
  final String content;
  const DateCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class NumberCell extends GridCell {
  final String content;
  const NumberCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class SingleSelectCell extends GridCell {
  final String content;
  const SingleSelectCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class MultiSelectCell extends GridCell {
  final String content;
  const MultiSelectCell(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(content);
  }
}

class BlankCell extends GridCell {
  const BlankCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
