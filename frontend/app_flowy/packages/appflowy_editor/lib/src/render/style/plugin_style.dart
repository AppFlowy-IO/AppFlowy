import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';

typedef TextStyleCustomizer = TextStyle Function(
    EditorState editorState, TextNode textNode);
typedef PaddingCustomizer = EdgeInsets Function(
    EditorState editorState, TextNode textNode);
typedef IconCustomizer = Widget Function(
    EditorState editorState, TextNode textNode);

class HeadingPluginStyle extends ThemeExtension<HeadingPluginStyle> {
  const HeadingPluginStyle({
    required this.textStyle,
    required this.padding,
  });

  final TextStyleCustomizer textStyle;
  final PaddingCustomizer padding;

  @override
  HeadingPluginStyle copyWith({
    TextStyleCustomizer? textStyle,
    PaddingCustomizer? padding,
  }) {
    return HeadingPluginStyle(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
    );
  }

  @override
  ThemeExtension<HeadingPluginStyle> lerp(
      ThemeExtension<HeadingPluginStyle>? other, double t) {
    if (other is! HeadingPluginStyle) {
      return this;
    }
    return HeadingPluginStyle(
      textStyle: other.textStyle,
      padding: other.padding,
    );
  }

  static final light = HeadingPluginStyle(
    padding: (_, __) => const EdgeInsets.symmetric(vertical: 8.0),
    textStyle: (editorState, textNode) {
      final headingToFontSize = {
        'h1': 32.0,
        'h2': 28.0,
        'h3': 24.0,
        'h4': 18.0,
        'h5': 18.0,
        'h6': 18.0,
      };
      final fontSize = headingToFontSize[textNode.attributes.heading] ?? 18.0;
      return TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      );
    },
  );

  static final dark = light;
}

class CheckboxPluginStyle extends ThemeExtension<CheckboxPluginStyle> {
  const CheckboxPluginStyle({
    required this.textStyle,
    required this.padding,
    required this.icon,
  });

  final TextStyleCustomizer textStyle;
  final PaddingCustomizer padding;
  final IconCustomizer icon;

  @override
  CheckboxPluginStyle copyWith({
    TextStyleCustomizer? textStyle,
    PaddingCustomizer? padding,
    IconCustomizer? icon,
  }) {
    return CheckboxPluginStyle(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      icon: icon ?? this.icon,
    );
  }

  @override
  ThemeExtension<CheckboxPluginStyle> lerp(
      ThemeExtension<CheckboxPluginStyle>? other, double t) {
    if (other is! CheckboxPluginStyle) {
      return this;
    }
    return CheckboxPluginStyle(
      textStyle: other.textStyle,
      padding: other.padding,
      icon: other.icon,
    );
  }

  static final light = CheckboxPluginStyle(
    padding: (_, __) => const EdgeInsets.symmetric(vertical: 8.0),
    textStyle: (editorState, textNode) => const TextStyle(),
    icon: (editorState, textNode) {
      final isCheck = textNode.attributes.check;
      const iconSize = Size.square(20.0);
      const iconPadding = EdgeInsets.only(right: 5.0);
      return FlowySvg(
        width: iconSize.width,
        height: iconSize.height,
        padding: iconPadding,
        name: isCheck ? 'check' : 'uncheck',
      );
    },
  );

  static final dark = light;
}

class BulletedListPluginStyle extends ThemeExtension<BulletedListPluginStyle> {
  const BulletedListPluginStyle({
    required this.textStyle,
    required this.padding,
    required this.icon,
  });

  final TextStyleCustomizer textStyle;
  final PaddingCustomizer padding;
  final IconCustomizer icon;

  @override
  BulletedListPluginStyle copyWith({
    TextStyleCustomizer? textStyle,
    PaddingCustomizer? padding,
    IconCustomizer? icon,
  }) {
    return BulletedListPluginStyle(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      icon: icon ?? this.icon,
    );
  }

  @override
  ThemeExtension<BulletedListPluginStyle> lerp(
      ThemeExtension<BulletedListPluginStyle>? other, double t) {
    if (other is! BulletedListPluginStyle) {
      return this;
    }
    return BulletedListPluginStyle(
      textStyle: other.textStyle,
      padding: other.padding,
      icon: other.icon,
    );
  }

  static final light = BulletedListPluginStyle(
    padding: (_, __) => const EdgeInsets.symmetric(vertical: 8.0),
    textStyle: (_, __) => const TextStyle(),
    icon: (_, __) {
      const iconSize = Size.square(20.0);
      const iconPadding = EdgeInsets.only(right: 5.0);
      return FlowySvg(
        width: iconSize.width,
        height: iconSize.height,
        padding: iconPadding,
        color: Colors.black,
        name: 'point',
      );
    },
  );

  static final dark = light.copyWith(icon: (_, __) {
    const iconSize = Size.square(20.0);
    const iconPadding = EdgeInsets.only(right: 5.0);
    return FlowySvg(
      width: iconSize.width,
      height: iconSize.height,
      padding: iconPadding,
      color: Colors.white,
      name: 'point',
    );
  });
}

class NumberListPluginStyle extends ThemeExtension<NumberListPluginStyle> {
  const NumberListPluginStyle({
    required this.textStyle,
    required this.padding,
    required this.icon,
  });

  final TextStyleCustomizer textStyle;
  final PaddingCustomizer padding;
  final IconCustomizer icon;

  @override
  NumberListPluginStyle copyWith({
    TextStyleCustomizer? textStyle,
    PaddingCustomizer? padding,
    IconCustomizer? icon,
  }) {
    return NumberListPluginStyle(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      icon: icon ?? this.icon,
    );
  }

  @override
  ThemeExtension<NumberListPluginStyle> lerp(
    ThemeExtension<NumberListPluginStyle>? other,
    double t,
  ) {
    if (other is! NumberListPluginStyle) {
      return this;
    }
    return NumberListPluginStyle(
      textStyle: other.textStyle,
      padding: other.padding,
      icon: other.icon,
    );
  }

  static final light = NumberListPluginStyle(
    padding: (_, __) => const EdgeInsets.symmetric(vertical: 8.0),
    textStyle: (_, __) => const TextStyle(),
    icon: (_, textNode) {
      const iconPadding = EdgeInsets.only(left: 5.0, right: 5.0);
      return Container(
        padding: iconPadding,
        child: Text(
          '${textNode.attributes.number.toString()}.',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      );
    },
  );

  static final dark = light.copyWith(icon: (editorState, textNode) {
    const iconPadding = EdgeInsets.only(left: 5.0, right: 5.0);
    return Container(
      padding: iconPadding,
      child: Text(
        '${textNode.attributes.number.toString()}.',
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  });
}

class QuotedTextPluginStyle extends ThemeExtension<QuotedTextPluginStyle> {
  const QuotedTextPluginStyle({
    required this.textStyle,
    required this.padding,
    required this.icon,
  });

  final TextStyleCustomizer textStyle;
  final PaddingCustomizer padding;
  final IconCustomizer icon;

  @override
  QuotedTextPluginStyle copyWith({
    TextStyleCustomizer? textStyle,
    PaddingCustomizer? padding,
    IconCustomizer? icon,
  }) {
    return QuotedTextPluginStyle(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      icon: icon ?? this.icon,
    );
  }

  @override
  ThemeExtension<QuotedTextPluginStyle> lerp(
      ThemeExtension<QuotedTextPluginStyle>? other, double t) {
    if (other is! QuotedTextPluginStyle) {
      return this;
    }
    return QuotedTextPluginStyle(
      textStyle: other.textStyle,
      padding: other.padding,
      icon: other.icon,
    );
  }

  static final light = QuotedTextPluginStyle(
    padding: (_, __) => const EdgeInsets.symmetric(vertical: 8.0),
    textStyle: (_, __) => const TextStyle(),
    icon: (_, __) {
      const iconSize = Size.square(20.0);
      const iconPadding = EdgeInsets.only(right: 5.0);
      return FlowySvg(
        width: iconSize.width,
        padding: iconPadding,
        name: 'quote',
      );
    },
  );

  static final dark = light;
}
