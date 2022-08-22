import 'package:appflowy_editor/appflowy_editor.dart';

abstract class Operation {
  factory Operation.fromJson(Map<String, dynamic> map) {
    String t = map["type"] as String;
    if (t == "insert-operation") {
      return InsertOperation.fromJson(map);
    } else if (t == "update-operation") {
      return UpdateOperation.fromJson(map);
    } else if (t == "delete-operation") {
      return DeleteOperation.fromJson(map);
    } else if (t == "text-edit-operation") {
      return TextEditOperation.fromJson(map);
    }

    throw ArgumentError('unexpected type $t');
  }
  final Path path;
  Operation(this.path);
  Operation copyWithPath(Path path);
  Operation invert();
  Map<String, dynamic> toJson();
}

class InsertOperation extends Operation {
  final List<Node> nodes;

  factory InsertOperation.fromJson(Map<String, dynamic> map) {
    final path = map["path"] as List<int>;
    final value =
        (map["nodes"] as List<dynamic>).map((n) => Node.fromJson(n)).toList();
    return InsertOperation(path, value);
  }

  InsertOperation(Path path, this.nodes) : super(path);

  InsertOperation copyWith({Path? path, List<Node>? nodes}) =>
      InsertOperation(path ?? this.path, nodes ?? this.nodes);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return DeleteOperation(
      path,
      nodes,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "insert-operation",
      "path": path.toList(),
      "nodes": nodes.map((n) => n.toJson()),
    };
  }
}

class UpdateOperation extends Operation {
  final Attributes attributes;
  final Attributes oldAttributes;

  factory UpdateOperation.fromJson(Map<String, dynamic> map) {
    final path = map["path"] as List<int>;
    final attributes = map["attributes"] as Map<String, dynamic>;
    final oldAttributes = map["oldAttributes"] as Map<String, dynamic>;
    return UpdateOperation(path, attributes, oldAttributes);
  }

  UpdateOperation(
    Path path,
    this.attributes,
    this.oldAttributes,
  ) : super(path);

  UpdateOperation copyWith(
          {Path? path, Attributes? attributes, Attributes? oldAttributes}) =>
      UpdateOperation(path ?? this.path, attributes ?? this.attributes,
          oldAttributes ?? this.oldAttributes);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return UpdateOperation(
      path,
      oldAttributes,
      attributes,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "update-operation",
      "path": path.toList(),
      "attributes": {...attributes},
      "oldAttributes": {...oldAttributes},
    };
  }
}

class DeleteOperation extends Operation {
  final List<Node> nodes;

  factory DeleteOperation.fromJson(Map<String, dynamic> map) {
    final path = map["path"] as List<int>;
    final List<Node> nodes =
        (map["nodes"] as List<dynamic>).map((e) => Node.fromJson(e)).toList();
    return DeleteOperation(path, nodes);
  }

  DeleteOperation(
    Path path,
    this.nodes,
  ) : super(path);

  DeleteOperation copyWith({Path? path, List<Node>? nodes}) =>
      DeleteOperation(path ?? this.path, nodes ?? this.nodes);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return InsertOperation(path, nodes);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "delete-operation",
      "path": path.toList(),
      "nodes": nodes.map((n) => n.toJson()),
    };
  }
}

class TextEditOperation extends Operation {
  final Delta delta;
  final Delta inverted;

  factory TextEditOperation.fromJson(Map<String, dynamic> map) {
    final path = map["path"] as List<int>;
    final delta = Delta.fromJson(map["delta"]);
    final invert = Delta.fromJson(map["invert"]);
    return TextEditOperation(path, delta, invert);
  }

  TextEditOperation(
    Path path,
    this.delta,
    this.inverted,
  ) : super(path);

  TextEditOperation copyWith({Path? path, Delta? delta, Delta? inverted}) =>
      TextEditOperation(
          path ?? this.path, delta ?? this.delta, inverted ?? this.inverted);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return TextEditOperation(path, inverted, delta);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "text-edit-operation",
      "path": path.toList(),
      "delta": delta.toJson(),
      "invert": inverted.toJson(),
    };
  }
}

Path transformPath(Path preInsertPath, Path b, [int delta = 1]) {
  if (preInsertPath.length > b.length) {
    return b;
  }
  if (preInsertPath.isEmpty || b.isEmpty) {
    return b;
  }
  // check the prefix
  for (var i = 0; i < preInsertPath.length - 1; i++) {
    if (preInsertPath[i] != b[i]) {
      return b;
    }
  }
  final prefix = preInsertPath.sublist(0, preInsertPath.length - 1);
  final suffix = b.sublist(preInsertPath.length);
  final preInsertLast = preInsertPath.last;
  final bAtIndex = b[preInsertPath.length - 1];
  if (preInsertLast <= bAtIndex) {
    prefix.add(bAtIndex + delta);
  } else {
    prefix.add(bAtIndex);
  }
  prefix.addAll(suffix);
  return prefix;
}

Operation transformOperation(Operation a, Operation b) {
  if (a is InsertOperation) {
    final newPath = transformPath(a.path, b.path, a.nodes.length);
    return b.copyWithPath(newPath);
  } else if (a is DeleteOperation) {
    final newPath = transformPath(a.path, b.path, -1 * a.nodes.length);
    return b.copyWithPath(newPath);
  }
  // TODO: transform update and textedit
  return b;
}
