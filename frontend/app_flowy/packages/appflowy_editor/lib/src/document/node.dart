import 'dart:collection';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/text_delta.dart';
import 'package:flutter/material.dart';
import './attributes.dart';

class Node extends ChangeNotifier with LinkedListEntry<Node> {
  Node? parent;
  final String type;
  final LinkedList<Node> children;
  Attributes _attributes;

  GlobalKey? key;
  // TODO: abstract a selectable node??
  final layerLink = LayerLink();

  String? get subtype {
    // TODO: make 'subtype' as a const value.
    if (_attributes.containsKey('subtype')) {
      assert(_attributes['subtype'] is String?,
          'subtype must be a [String] or [null]');
      return _attributes['subtype'] as String?;
    }
    return null;
  }

  String get id {
    if (subtype != null) {
      return '$type/$subtype';
    }
    return type;
  }

  Path get path => _path();

  Attributes get attributes => _attributes;

  Node({
    required this.type,
    required this.children,
    required Attributes attributes,
    this.parent,
  }) : _attributes = attributes {
    for (final child in children) {
      child.parent = this;
    }
  }

  factory Node.fromJson(Map<String, Object> json) {
    assert(json['type'] is String);

    // TODO: check the type that not exist on plugins.
    final jType = json['type'] as String;
    final jChildren = json['children'] as List?;
    final jAttributes = json['attributes'] != null
        ? Attributes.from(json['attributes'] as Map)
        : Attributes.from({});

    final LinkedList<Node> children = LinkedList();
    if (jChildren != null) {
      children.addAll(
        jChildren.map(
          (jChild) => Node.fromJson(
            Map<String, Object>.from(jChild),
          ),
        ),
      );
    }

    Node node;

    if (jType == "text") {
      final jDelta = json['delta'] as List<dynamic>?;
      final delta = jDelta == null ? Delta() : Delta.fromJson(jDelta);
      node = TextNode(
          type: jType,
          children: children,
          attributes: jAttributes,
          delta: delta);
    } else {
      node = Node(
        type: jType,
        children: children,
        attributes: jAttributes,
      );
    }

    for (final child in children) {
      child.parent = node;
    }

    return node;
  }

  void updateAttributes(Attributes attributes) {
    final oldAttributes = {..._attributes};
    _attributes = composeAttributes(_attributes, attributes) ?? {};

    // Notifies the new attributes
    // if attributes contains 'subtype', should notify parent to rebuild node
    // else, just notify current node.
    bool shouldNotifyParent =
        _attributes['subtype'] != oldAttributes['subtype'];
    shouldNotifyParent ? parent?.notifyListeners() : notifyListeners();
  }

  Node? childAtIndex(int index) {
    if (children.length <= index) {
      return null;
    }

    return children.elementAt(index);
  }

  Node? childAtPath(Path path) {
    if (path.isEmpty) {
      return this;
    }

    return childAtIndex(path.first)?.childAtPath(path.sublist(1));
  }

  void insert(Node entry, {int? index}) {
    index ??= children.length;

    if (children.isEmpty) {
      entry.parent = this;
      children.add(entry);
      notifyListeners();
      return;
    }

    final length = children.length;

    if (index >= length) {
      children.last.insertAfter(entry);
    } else if (index <= 0) {
      children.first.insertBefore(entry);
    } else {
      childAtIndex(index)?.insertBefore(entry);
    }
  }

  @override
  void insertAfter(Node entry) {
    entry.parent = parent;
    super.insertAfter(entry);

    // Notifies the new node.
    parent?.notifyListeners();
  }

  @override
  void insertBefore(Node entry) {
    entry.parent = parent;
    super.insertBefore(entry);

    // Notifies the new node.
    parent?.notifyListeners();
  }

  @override
  void unlink() {
    super.unlink();

    parent?.notifyListeners();
    parent = null;
  }

  Map<String, Object> toJson() {
    var map = <String, Object>{
      'type': type,
    };
    if (children.isNotEmpty) {
      map['children'] =
          (children.map((node) => node.toJson())).toList(growable: false);
    }
    if (_attributes.isNotEmpty) {
      map['attributes'] = _attributes;
    }
    return map;
  }

  Path _path([Path previous = const []]) {
    if (parent == null) {
      return previous;
    }
    var index = 0;
    for (var child in parent!.children) {
      if (child == this) {
        break;
      }
      index += 1;
    }
    return parent!._path([index, ...previous]);
  }

  Node copyWith({
    String? type,
    LinkedList<Node>? children,
    Attributes? attributes,
  }) {
    final node = Node(
      type: type ?? this.type,
      attributes: attributes ?? {..._attributes},
      children: children ?? LinkedList(),
    );
    if (children == null && this.children.isNotEmpty) {
      for (final child in this.children) {
        node.children.add(
          child.copyWith()..parent = node,
        );
      }
    }
    return node;
  }
}

class TextNode extends Node {
  Delta _delta;

  TextNode({
    required super.type,
    required Delta delta,
    LinkedList<Node>? children,
    Attributes? attributes,
  })  : _delta = delta,
        super(
          children: children ?? LinkedList(),
          attributes: attributes ?? {},
        );

  TextNode.empty({Attributes? attributes})
      : _delta = Delta([TextInsert('')]),
        super(
          type: 'text',
          children: LinkedList(),
          attributes: attributes ?? {},
        );

  Delta get delta {
    return _delta;
  }

  set delta(Delta v) {
    _delta = v;
    notifyListeners();
  }

  @override
  Map<String, Object> toJson() {
    final map = super.toJson();
    map['delta'] = _delta.toJson();
    return map;
  }

  @override
  TextNode copyWith({
    String? type,
    LinkedList<Node>? children,
    Attributes? attributes,
    Delta? delta,
  }) {
    final textNode = TextNode(
      type: type ?? this.type,
      children: children,
      attributes: attributes ?? _attributes,
      delta: delta ?? this.delta,
    );
    if (children == null && this.children.isNotEmpty) {
      for (final child in this.children) {
        textNode.children.add(
          child.copyWith()..parent = textNode,
        );
      }
    }
    return textNode;
  }

  String toRawString() => _delta.toRawString();
}
