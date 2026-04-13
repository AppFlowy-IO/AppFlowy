import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'hashtag_block_keys.dart';

class HashtagBlock extends StatelessWidget {
  const HashtagBlock({
    super.key,
    required this.data,
    required this.textStyle,
  });

  final Map<String, dynamic> data;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final tag = data[HashtagBlockKeys.name] as String? ?? '';

    if (tag.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$tag',
        style: textStyle?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}