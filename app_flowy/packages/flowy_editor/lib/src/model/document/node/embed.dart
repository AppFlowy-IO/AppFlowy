/// An object which can be embedded into a Quill document.
///
/// See also:
///
/// * [BlockEmbed] which represents a block embed.
class Embeddable {
  Map<String, dynamic> toJson() => <String, String>{type: data};

  static Embeddable fromJson(Map<String, dynamic> json) {
    final mp = Map<String, dynamic>.from(json);
    assert(mp.length == 1, 'Embeddable map has one key');
    return BlockEmbed(mp.keys.first, mp.values.first);
  }

  /// The type of this object.
  final String type;

  /// The data payload of this object
  final dynamic data;

  Embeddable(this.type, this.data);
}

/// An object which occupies an entire line in a document and cannot co-exist
/// inline with regular text.
///
/// There are two built-in embed types supported by Quill documents, however
/// the document model itself does not make any assumptions about the types
/// of embedded objects and allows users to define their own types.
class BlockEmbed extends Embeddable {
  BlockEmbed(String type, String data) : super(type, data);

  static BlockEmbed horizontalRule = BlockEmbed('divider', 'hr');

  static BlockEmbed image(String imageUrl) => BlockEmbed('image', imageUrl);
}
