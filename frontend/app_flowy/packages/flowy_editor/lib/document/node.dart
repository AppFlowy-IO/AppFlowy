import 'dart:collection';

class Node extends LinkedListEntry<Node> {
  Node? parent;
  final String type;
  final LinkedList<Node> children;
  final Map<String, Object> attributes;

  Node({
    required this.type,
    required this.children,
    required this.attributes,
    this.parent,
  });

  factory Node.fromJson(Map<String, Object> json) {
    assert(json['type'] is String);

    final jType = json['type'] as String;
    final jChildren = json['children'] as List?;
    final jAttributes = json['attributes'] != null
        ? Map<String, Object>.from(json['attributes'] as Map)
        : <String, Object>{};

    final LinkedList<Node> children = LinkedList();
    if (jChildren != null) {
      children.addAll(
        jChildren.map(
          (jnode) => Node.fromJson(
            Map<String, Object>.from(jnode),
          ),
        ),
      );
    }

    return Node(
      type: jType,
      children: children,
      attributes: jAttributes,
    );
  }

  Map<String, Object> toJson() {
    var map = <String, Object>{
      'type': type,
    };
    if (children.isNotEmpty) {
      map['children'] = children.map((node) => node.toJson());
    }
    if (attributes.isNotEmpty) {
      map['attributes'] = attributes;
    }
    return map;
  }
}
