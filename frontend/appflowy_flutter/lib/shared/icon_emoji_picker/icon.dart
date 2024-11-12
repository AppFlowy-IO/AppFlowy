import 'package:json_annotation/json_annotation.dart';

part 'icon.g.dart';

@JsonSerializable()
class IconGroup {
  factory IconGroup.fromJson(Map<String, dynamic> json) {
    final group = _$IconGroupFromJson(json);
    // Set the iconGroup reference for each icon
    for (final icon in group.icons) {
      icon.iconGroup = group;
    }
    return group;
  }

  factory IconGroup.fromMapEntry(MapEntry<String, dynamic> entry) =>
      IconGroup.fromJson({
        'name': entry.key,
        'icons': entry.value,
      });

  IconGroup({
    required this.name,
    required this.icons,
  }) {
    // Set the iconGroup reference for each icon
    for (final icon in icons) {
      icon.iconGroup = this;
    }
  }

  final String name;
  final List<Icon> icons;

  String get displayName => name.replaceAll('_', ' ');

  IconGroup filter(String keyword) {
    final filteredIcons = icons
        .where(
          (icon) => icon.keywords.any((k) => k.contains(keyword.toLowerCase())),
        )
        .toList();
    return IconGroup(name: name, icons: filteredIcons);
  }

  String? getSvgContent(String iconName) {
    final icon = icons.firstWhere(
      (icon) => icon.name == iconName,
    );
    return icon.content;
  }

  Map<String, dynamic> toJson() => _$IconGroupToJson(this);
}

@JsonSerializable()
class Icon {
  factory Icon.fromJson(Map<String, dynamic> json) => _$IconFromJson(json);

  Icon({
    required this.name,
    required this.keywords,
    required this.content,
  });

  final String name;
  final List<String> keywords;
  final String content;

  // Add reference to parent IconGroup
  IconGroup? iconGroup;

  String get displayName => name.replaceAll('-', ' ');

  Map<String, dynamic> toJson() => _$IconToJson(this);

  String get iconPath {
    if (iconGroup == null) {
      return '';
    }
    return '${iconGroup!.name}/$name';
  }
}
