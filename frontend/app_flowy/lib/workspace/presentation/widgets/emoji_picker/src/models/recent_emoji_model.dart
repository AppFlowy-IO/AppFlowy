import 'emoji_model.dart';

/// Class that holds an recent emoji
/// Recent Emoji has an instance of the emoji
/// And a counter, which counts how often this emoji
/// has been used before
class RecentEmoji {
  /// Constructor
  RecentEmoji(this.emoji, this.counter);

  /// Emoji instance
  final Emoji emoji;

  /// Counter how often emoji has been used before
  int counter = 0;

  /// Parse RecentEmoji from json
  static RecentEmoji fromJson(dynamic json) {
    return RecentEmoji(
      Emoji.fromJson(json['emoji'] as Map<String, dynamic>),
      json['counter'] as int,
    );
  }

  /// Encode RecentEmoji to json
  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'counter': counter,
      };
}
