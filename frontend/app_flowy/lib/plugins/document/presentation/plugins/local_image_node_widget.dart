import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'dart:io';

const String kLocalImage = 'image';
String? folderPath;
String? imageFile;
String? newImage;

Future<String?> copyFile(String src, String? dest, String name) async {
  var path = File(src);
  path.copy('$dest/images/$name');
  newImage = '$dest/images/$name';
  return newImage;
}

Future<Future<Directory>?> checkDir() async {
  if (await Directory('$folderPath/images').exists() == false) {
    return Directory('$folderPath/images').create(recursive: true);
  }
  return null;
}

class LocalImageNodeWidgetBuilder extends NodeWidgetBuilder {
  LocalImageNodeWidgetBuilder(this.directory);
  final Future<Directory>? directory;

  @override
  Widget build(NodeWidgetContext<Node> context) {
    String src = context.node.attributes['image_src'].toString();
    String imageName = context.node.attributes['name'];
    var storageLocation = directory?.then((location) async {
      String value = location.path.toString();
      folderPath = value;
      checkDir();
      return folderPath;
    });

    copyFile(src, folderPath, imageName);
    return _LocalImageNodeWidget(
        key: context.node.key, node: context.node, image: newImage);
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        checkDir();
        return node.type == 'image' &&
            node.attributes['image_src'] is String &&
            node.attributes['name'] is String;
      };
}

class _LocalImageNodeWidget extends StatefulWidget {
  const _LocalImageNodeWidget({Key? key, required this.node, this.image})
      : super(key: key);

  final Node node;
  final String? image;

  @override
  State<StatefulWidget> createState() => __LocalImageNodeWidgetState();
}

class __LocalImageNodeWidgetState extends State<_LocalImageNodeWidget>
    with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(widget.image.toString()),
      height: 200,
    );
  }

  @override
  Position start() {
    return Position(path: widget.node.path, offset: 0);
  }

  @override
  Position end() {
    return Position(path: widget.node.path, offset: 1);
  }

  @override
  Position getPositionInOffset(Offset start) {
    return end();
  }

  @override
  Rect? getCursorRectInPosition(Position position) {
    return null;
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    return [Offset.zero & _renderBox.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    if (start <= end) {
      return Selection(start: this.start(), end: this.end());
    } else {
      return Selection(start: this.end(), end: this.start());
    }
  }

  @override
  Offset localToGlobal(Offset offset) {
    return _renderBox.localToGlobal(offset);
  }
}
