import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'dart:io';

const String kLocalImage = 'image';
String? folderPath;
String? imageFile;
String? newImage;

String? copyFile(String src, String? dest, String name) {
  try {
    var path = File(src);
    path.copySync('$dest/images/$name');
    newImage = '$dest/images/$name';
    return newImage;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

Directory? checkDir(String? path) {
  Directory dir = Directory('$path/images');
  try {
    if (!Directory('$path/images').existsSync()) {
      dir.createSync(recursive: true);
      return dir;
    }
    return dir;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

class LocalImageNodeWidgetBuilder extends NodeWidgetBuilder {
  LocalImageNodeWidgetBuilder({this.imageFolder});
  final Future<Directory>? imageFolder;

  @override
  Widget build(NodeWidgetContext<Node> context) {
    String src = context.node.attributes['image_src'].toString();
    String imageName = context.node.attributes['name'];

    imageFolder?.then((location) async {
      String value = location.path.toString();
      folderPath = value;
      checkDir(value);
      return value;
    });

    Future<String?> checkImg() async {
      File existingFile = File('$folderPath/images/$imageName');
      try {
        if (existingFile.existsSync()) {
          return newImage = existingFile.path.toString();
        }
        return copyFile(src, folderPath, imageName);
      } catch (e) {
        debugPrint(e.toString());
        return null;
      }
    }

    return FutureBuilder(
        future: checkImg(),
        builder: (BuildContext _, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return _LocalImageNodeWidget(
                  key: context.node.key,
                  node: context.node,
                  image: snapshot.data);
            } else if (snapshot.hasError) {
              return Text('Can not load image ${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
          } else {
            return const CircularProgressIndicator();
          }
        });
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
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
