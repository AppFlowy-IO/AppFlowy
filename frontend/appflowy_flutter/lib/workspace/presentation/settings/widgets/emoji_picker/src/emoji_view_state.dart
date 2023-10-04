import 'models/category_models.dart';
import 'emoji_picker.dart';

/// State that holds current emoji data
class EmojiViewState {
  /// Constructor
  EmojiViewState(
    this.categoryEmoji,
    this.onEmojiSelected,
    this.onBackspacePressed,
  );

  /// List of all category including their emoji
  final List<CategoryEmoji> categoryEmoji;

  /// Callback when pressed on emoji
  final OnEmojiSelected onEmojiSelected;

  /// Callback when pressed on backspace
  final OnBackspacePressed? onBackspacePressed;
}
