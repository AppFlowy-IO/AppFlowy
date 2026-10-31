import 'tag.dart';

class TagFilter {
  static bool match({
    required List<Tag> tags,
    required String query,
  }) {
    if (query.isEmpty) return true;

    final lower = query.toLowerCase();
    return tags.any((tag) => tag.name.toLowerCase().contains(lower));
  }
}
