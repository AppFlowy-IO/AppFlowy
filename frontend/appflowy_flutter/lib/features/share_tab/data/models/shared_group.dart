class SharedGroup {
  SharedGroup({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;

  final String name;

  final String icon;

  SharedGroup copyWith({
    String? id,
    String? name,
    String? icon,
  }) {
    return SharedGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }
}
