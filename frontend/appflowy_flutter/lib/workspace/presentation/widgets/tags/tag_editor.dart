import 'package:flutter/material.dart';
import '../../../application/tag/tag.dart';

class TagEditor extends StatefulWidget {
  final List<Tag> tags;
  final ValueChanged<List<Tag>> onChanged;

  const TagEditor({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final controller = TextEditingController();

  void _addTag(String value) {
    if (value.trim().isEmpty) return;

    widget.onChanged([
      ...widget.tags,
      Tag(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: value.trim(),
        color: Colors.blue.value,
      ),
    ]);

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: widget.tags.map((tag) {
            return Chip(
              label: Text(tag.name),
              onDeleted: () {
                widget.onChanged(
                  widget.tags.where((t) => t.id != tag.id).toList(),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onSubmitted: _addTag,
          decoration: const InputDecoration(
            hintText: 'Add tag',
            isDense: true,
          ),
        ),
      ],
    );
  }
}
