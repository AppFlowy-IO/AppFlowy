import 'models/emoji_category_models.dart';
import 'emoji_picker.dart';

/// State that holds current emoji data
class EmojiViewState {
  /// Constructor
  EmojiViewState(
    this.emojiCategoryGroupList,
    this.onEmojiSelected,
    this.onBackspacePressed,
  );

  /// List of all categories including their emojis
  final List<EmojiCategoryGroup> emojiCategoryGroupList;

  /// Callback when pressed on emoji
  final OnEmojiSelected onEmojiSelected;

  /// Callback when pressed on backspace
  final OnBackspacePressed? onBackspacePressed;
}
