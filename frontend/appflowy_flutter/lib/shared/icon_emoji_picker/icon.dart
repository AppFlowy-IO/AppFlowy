import 'package:json_annotation/json_annotation.dart';

part 'icon.g.dart';

@JsonSerializable()
class IconGroup {
  factory IconGroup.fromJson(Map<String, dynamic> json) =>
      _$IconGroupFromJson(json);

  factory IconGroup.fromMapEntry(MapEntry<String, dynamic> entry) =>
      IconGroup.fromJson({
        'name': entry.key,
        'icons': entry.value,
      });

  IconGroup({
    required this.name,
    required this.icons,
  });

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

  String get displayName => name.replaceAll('-', ' ');

  Map<String, dynamic> toJson() => _$IconToJson(this);
}
