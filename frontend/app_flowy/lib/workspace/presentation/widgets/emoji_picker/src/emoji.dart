/// A class to store data for each individual emoji
class Emoji {
  /// Emoji constructor
  const Emoji(this.name, this.emoji);

  /// The name or description for this emoji
  final String name;

  /// The unicode string for this emoji
  ///
  /// This is the string that should be displayed to view the emoji
  final String emoji;

  @override
  String toString() {
    // return 'Name: $name, Emoji: $emoji';
    return name;
  }

  /// Parse Emoji from json
  static Emoji fromJson(Map<String, dynamic> json) {
    return Emoji(json['name'] as String, json['emoji'] as String);
  }

  ///  Encode Emoji to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emoji': emoji,
    };
  }
}
