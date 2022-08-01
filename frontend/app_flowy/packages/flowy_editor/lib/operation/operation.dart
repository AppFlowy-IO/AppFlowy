import 'package:flowy_editor/document/attributes.dart';
import 'package:flowy_editor/flowy_editor.dart';

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
  final Node value;

  factory InsertOperation.fromJson(Map<String, dynamic> map) {
    final path = map["path"] as List<int>;
    final value = Node.fromJson(map["value"]);
    return InsertOperation(path, value);
  }

  InsertOperation(Path path, this.value) : super(path);

  InsertOperation copyWith({Path? path, Node? value}) =>
      InsertOperation(path ?? this.path, value ?? this.value);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return DeleteOperation(
      path,
      value,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "insert-operation",
      "path": path.toList(),
      "value": value.toJson(),
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
  final Node removedValue;

  factory DeleteOperation.fromJson(Map<String, dynamic> map) {
    final path = map["path"] as List<int>;
    final removedValue = Node.fromJson(map["removedValue"]);
    return DeleteOperation(path, removedValue);
  }

  DeleteOperation(
    Path path,
    this.removedValue,
  ) : super(path);

  DeleteOperation copyWith({Path? path, Node? removedValue}) =>
      DeleteOperation(path ?? this.path, removedValue ?? this.removedValue);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return InsertOperation(path, removedValue);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "delete-operation",
      "path": path.toList(),
      "removedValue": removedValue.toJson(),
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
    final newPath = transformPath(a.path, b.path);
    return b.copyWithPath(newPath);
  } else if (b is DeleteOperation) {
    final newPath = transformPath(a.path, b.path, -1);
    return b.copyWithPath(newPath);
  }
  // TODO: transform update and textedit
  return b;
}
