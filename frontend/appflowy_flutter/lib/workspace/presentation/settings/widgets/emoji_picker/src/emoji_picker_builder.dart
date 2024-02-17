import 'package:flutter/material.dart';

import 'emji_picker_config.dart';
import 'emoji_view_state.dart';

/// Template class for custom implementation
/// Inherit this class to create your own EmojiPicker
abstract class EmojiPickerBuilder extends StatefulWidget {
  /// Constructor
  const EmojiPickerBuilder(this.config, this.state, {super.key});

  /// Config for customizations
  final EmojiPickerConfig config;

  /// State that holds current emoji data
  final EmojiViewState state;
}
