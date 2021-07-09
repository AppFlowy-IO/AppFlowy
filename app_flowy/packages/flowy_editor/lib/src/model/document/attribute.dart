import 'package:quiver/core.dart';

enum AttributeScope {
  INLINE, // refer to https://quilljs.com/docs/formats/#inline
  BLOCK, // refer to https://quilljs.com/docs/formats/#block
  EMBEDS, // refer to https://quilljs.com/docs/formats/#embeds
  IGNORE, // attributes that can be ignored
}

class Attribute<T> {
  Attribute(this.key, this.scope, this.value);

  final String key;
  final AttributeScope scope;
  final T value;

  static final Map<String, Attribute> _registry = {
    Attribute.bold.key: Attribute.bold,
    Attribute.italic.key: Attribute.italic,
    Attribute.underline.key: Attribute.underline,
    Attribute.strikeThrough.key: Attribute.strikeThrough,
    Attribute.font.key: Attribute.font,
    Attribute.size.key: Attribute.size,
    Attribute.link.key: Attribute.link,
    Attribute.color.key: Attribute.color,
    Attribute.background.key: Attribute.background,
    Attribute.placeholder.key: Attribute.placeholder,
    Attribute.header.key: Attribute.header,
    Attribute.indent.key: Attribute.indent,
    Attribute.align.key: Attribute.align,
    Attribute.list.key: Attribute.list,
    Attribute.codeBlock.key: Attribute.codeBlock,
    Attribute.quoteBlock.key: Attribute.quoteBlock,
    Attribute.width.key: Attribute.width,
    Attribute.height.key: Attribute.height,
    Attribute.style.key: Attribute.style,
    Attribute.token.key: Attribute.token,
  };

  // Attribute Properties

  static final BoldAttribute bold = BoldAttribute();

  static final ItalicAttribute italic = ItalicAttribute();

  static final UnderlineAttribute underline = UnderlineAttribute();

  static final StrikeThroughAttribute strikeThrough = StrikeThroughAttribute();

  static final FontAttribute font = FontAttribute(null);

  static final SizeAttribute size = SizeAttribute(null);

  static final LinkAttribute link = LinkAttribute(null);

  static final ColorAttribute color = ColorAttribute(null);

  static final BackgroundAttribute background = BackgroundAttribute(null);

  static final PlaceholderAttribute placeholder = PlaceholderAttribute();

  static final HeaderAttribute header = HeaderAttribute();

  static final IndentAttribute indent = IndentAttribute();

  static final AlignAttribute align = AlignAttribute(null);

  static final ListAttribute list = ListAttribute(null);

  static final CodeBlockAttribute codeBlock = CodeBlockAttribute();

  static final QuoteBlockAttribute quoteBlock = QuoteBlockAttribute();

  static final WidthAttribute width = WidthAttribute(null);

  static final HeightAttribute height = HeightAttribute(null);

  static final StyleAttribute style = StyleAttribute(null);

  static final TokenAttribute token = TokenAttribute('');

  static Attribute<int?> get h1 => HeaderAttribute(level: 1);

  static Attribute<int?> get h2 => HeaderAttribute(level: 2);

  static Attribute<int?> get h3 => HeaderAttribute(level: 3);

  static Attribute<int?> get h4 => HeaderAttribute(level: 4);

  static Attribute<int?> get h5 => HeaderAttribute(level: 5);

  static Attribute<int?> get h6 => HeaderAttribute(level: 6);

  static Attribute<String?> get leftAlignment => AlignAttribute('left');

  static Attribute<String?> get centerAlignment => AlignAttribute('center');

  static Attribute<String?> get rightAlignment => AlignAttribute('right');

  static Attribute<String?> get justifyAlignment => AlignAttribute('justify');

  static Attribute<String?> get bullet => ListAttribute('bullet');

  static Attribute<String?> get ordered => ListAttribute('ordered');

  static Attribute<String?> get checked => ListAttribute('checked');

  static Attribute<String?> get unchecked => ListAttribute('unchecked');

  static Attribute<int?> get indentL1 => IndentAttribute(level: 1);

  static Attribute<int?> get indentL2 => IndentAttribute(level: 2);

  static Attribute<int?> get indentL3 => IndentAttribute(level: 3);

  static Attribute<int?> get indentL4 => IndentAttribute(level: 4);

  static Attribute<int?> get indentL5 => IndentAttribute(level: 5);

  static Attribute<int?> get indentL6 => IndentAttribute(level: 6);

  static Attribute<int?> getIndentLevel(int? level) {
    switch (level) {
      case 1:
        return indentL1;
      case 2:
        return indentL2;
      case 3:
        return indentL3;
      case 4:
        return indentL4;
      case 5:
        return indentL5;
      default:
        return indentL6;
    }
  }

  // Keys Container
  static final Set<String> inlineKeys = {
    Attribute.bold.key,
    Attribute.italic.key,
    Attribute.underline.key,
    Attribute.strikeThrough.key,
    Attribute.link.key,
    Attribute.color.key,
    Attribute.background.key,
    Attribute.placeholder.key,
  };

  static final Set<String> blockKeys = {
    Attribute.header.key,
    Attribute.indent.key,
    Attribute.align.key,
    Attribute.list.key,
    Attribute.codeBlock.key,
    Attribute.quoteBlock.key,
  };

  static final Set<String> blockKeysExceptHeader = blockKeys
    ..remove(Attribute.header.key);

  // Utils

  bool get isInline => AttributeScope.INLINE == scope;

  bool get isIgnored => AttributeScope.IGNORE == scope;

  bool get isBlockExceptHeader => blockKeysExceptHeader.contains(key);

  Map<String, dynamic> toJson() => <String, dynamic>{key: value};

  static Attribute fromKeyValue(String key, dynamic value) {
    if (!_registry.containsKey(key)) {
      throw ArgumentError.value(key, 'key "$key" not found.');
    }
    final origin = _registry[key]!;
    final attribute = clone(origin, value);
    return attribute;
  }

  static Attribute clone(Attribute origin, dynamic value) {
    return Attribute(origin.key, origin.scope, value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Attribute<T>) return false;
    final typedOther = other;
    return key == typedOther.key &&
        scope == typedOther.scope &&
        value == typedOther.value;
  }

  @override
  int get hashCode => hash3(key, scope, value);

  @override
  String toString() {
    return 'Attribute{key: $key, scope: $scope, value: $value}';
  }
}

/* -------------------------------------------------------------------------- */
/*                               Attributes Impl                              */
/* -------------------------------------------------------------------------- */

/* --------------------------------- INLINE --------------------------------- */

class BoldAttribute extends Attribute<bool> {
  BoldAttribute() : super('bold', AttributeScope.INLINE, true);
}

class ItalicAttribute extends Attribute<bool> {
  ItalicAttribute() : super('italic', AttributeScope.INLINE, true);
}

class UnderlineAttribute extends Attribute<bool> {
  UnderlineAttribute() : super('underline', AttributeScope.INLINE, true);
}

class StrikeThroughAttribute extends Attribute<bool> {
  StrikeThroughAttribute()
      : super('strikethrough', AttributeScope.INLINE, true);
}

class FontAttribute extends Attribute<String?> {
  FontAttribute(String? value) : super('font', AttributeScope.INLINE, value);
}

class SizeAttribute extends Attribute<String?> {
  SizeAttribute(String? value) : super('size', AttributeScope.INLINE, value);
}

class LinkAttribute extends Attribute<String?> {
  LinkAttribute(String? value) : super('link', AttributeScope.INLINE, value);
}

class ColorAttribute extends Attribute<String?> {
  ColorAttribute(String? value) : super('color', AttributeScope.INLINE, value);
}

class BackgroundAttribute extends Attribute<String?> {
  BackgroundAttribute(String? value)
      : super('background', AttributeScope.INLINE, value);
}

class PlaceholderAttribute extends Attribute<bool?> {
  PlaceholderAttribute() : super('placeholder', AttributeScope.INLINE, true);
}

/* ---------------------------------- BLOCK --------------------------------- */

class HeaderAttribute extends Attribute<int?> {
  HeaderAttribute({int? level}) : super('header', AttributeScope.BLOCK, level);
}

class IndentAttribute extends Attribute<int?> {
  IndentAttribute({int? level}) : super('indent', AttributeScope.BLOCK, level);
}

class AlignAttribute extends Attribute<String?> {
  AlignAttribute(String? value) : super('align', AttributeScope.BLOCK, value);
}

class ListAttribute extends Attribute<String?> {
  ListAttribute(String? value) : super('list', AttributeScope.BLOCK, value);
}

class CodeBlockAttribute extends Attribute<bool?> {
  CodeBlockAttribute() : super('code_block', AttributeScope.BLOCK, true);
}

class QuoteBlockAttribute extends Attribute<bool?> {
  QuoteBlockAttribute() : super('quote_block', AttributeScope.BLOCK, true);
}

/* --------------------------------- IGNORE --------------------------------- */

class WidthAttribute extends Attribute<String?> {
  WidthAttribute(String? value) : super('width', AttributeScope.IGNORE, value);
}

class HeightAttribute extends Attribute<String?> {
  HeightAttribute(String? value)
      : super('height', AttributeScope.IGNORE, value);
}

class StyleAttribute extends Attribute<String?> {
  StyleAttribute(String? value) : super('style', AttributeScope.IGNORE, value);
}

class TokenAttribute extends Attribute<String?> {
  TokenAttribute(String? value) : super('token', AttributeScope.IGNORE, value);
}
