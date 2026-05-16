// workaround for toolbar theme color.

import 'package:flutter/material.dart';

class ToolbarColorExtension extends ThemeExtension<ToolbarColorExtension> {
  factory ToolbarColorExtension.light() => const ToolbarColorExtension(
        toolbarBackgroundColor: Color(0xFFFFFFFF),
        toolbarItemIconColor: Color(0xFF1F2329),
        toolbarItemIconDisabledColor: Color(0xFF999BA0),
        toolbarItemIconSelectedColor: Color(0x1F232914),
        toolbarItemSelectedBackgroundColor: Color(0xFFF2F2F2),
        toolbarMenuBackgroundColor: Color(0xFFFFFFFF),
        toolbarMenuItemBackgroundColor: Color(0xFFF2F2F7),
        toolbarMenuItemSelectedBackgroundColor: Color(0xFF00BCF0),
        toolbarMenuIconColor: Color(0xFF1F2329),
        toolbarMenuIconDisabledColor: Color(0xFF999BA0),
        toolbarMenuIconSelectedColor: Color(0xFFFFFFFF),
        toolbarShadowColor: Color(0x2D000000),
      );

  factory ToolbarColorExtension.dark() => const ToolbarColorExtension(
        toolbarBackgroundColor: Color(0xFF1F2329),
        toolbarItemIconColor: Color(0xFFF3F3F8),
        toolbarItemIconDisabledColor: Color(0xFF55565B),
        toolbarItemIconSelectedColor: Color(0xFF00BCF0),
        toolbarItemSelectedBackgroundColor: Color(0xFF3A3D43),
        toolbarMenuBackgroundColor: Color(0xFF23262B),
        toolbarMenuItemBackgroundColor: Color(0xFF2D3036),
        toolbarMenuItemSelectedBackgroundColor: Color(0xFF00BCF0),
        toolbarMenuIconColor: Color(0xFFF3F3F8),
        toolbarMenuIconDisabledColor: Color(0xFF55565B),
        toolbarMenuIconSelectedColor: Color(0xFF1F2329),
        toolbarShadowColor: Color.fromARGB(80, 112, 112, 112),
      );

  factory ToolbarColorExtension.fromBrightness(Brightness brightness) =>
      brightness == Brightness.light
          ? ToolbarColorExtension.light()
          : ToolbarColorExtension.dark();

  const ToolbarColorExtension({
    required this.toolbarBackgroundColor,
    required this.toolbarItemIconColor,
    required this.toolbarItemIconDisabledColor,
    required this.toolbarItemIconSelectedColor,
    required this.toolbarMenuBackgroundColor,
    required this.toolbarMenuItemBackgroundColor,
    required this.toolbarMenuItemSelectedBackgroundColor,
    required this.toolbarItemSelectedBackgroundColor,
    required this.toolbarMenuIconColor,
    required this.toolbarMenuIconDisabledColor,
    required this.toolbarMenuIconSelectedColor,
    required this.toolbarShadowColor,
  });

  final Color toolbarBackgroundColor;

  final Color toolbarItemIconColor;
  final Color toolbarItemIconDisabledColor;
  final Color toolbarItemIconSelectedColor;
  final Color toolbarItemSelectedBackgroundColor;

  final Color toolbarMenuBackgroundColor;
  final Color toolbarMenuItemBackgroundColor;
  final Color toolbarMenuItemSelectedBackgroundColor;
  final Color toolbarMenuIconColor;
  final Color toolbarMenuIconDisabledColor;
  final Color toolbarMenuIconSelectedColor;

  final Color toolbarShadowColor;

  static ToolbarColorExtension of(BuildContext context) {
    return Theme.of(context).extension<ToolbarColorExtension>()!;
  }

  @override
  ToolbarColorExtension copyWith({
    Color? toolbarBackgroundColor,
    Color? toolbarItemIconColor,
    Color? toolbarItemIconDisabledColor,
    Color? toolbarItemIconSelectedColor,
    Color? toolbarMenuBackgroundColor,
    Color? toolbarItemSelectedBackgroundColor,
    Color? toolbarMenuItemBackgroundColor,
    Color? toolbarMenuItemSelectedBackgroundColor,
    Color? toolbarMenuIconColor,
    Color? toolbarMenuIconDisabledColor,
    Color? toolbarMenuIconSelectedColor,
    Color? toolbarShadowColor,
  }) {
    return ToolbarColorExtension(
      toolbarBackgroundColor:
          toolbarBackgroundColor ?? this.toolbarBackgroundColor,
      toolbarItemIconColor: toolbarItemIconColor ?? this.toolbarItemIconColor,
      toolbarItemIconDisabledColor:
          toolbarItemIconDisabledColor ?? this.toolbarItemIconDisabledColor,
      toolbarItemIconSelectedColor:
          toolbarItemIconSelectedColor ?? this.toolbarItemIconSelectedColor,
      toolbarItemSelectedBackgroundColor: toolbarItemSelectedBackgroundColor ??
          this.toolbarItemSelectedBackgroundColor,
      toolbarMenuBackgroundColor:
          toolbarMenuBackgroundColor ?? this.toolbarMenuBackgroundColor,
      toolbarMenuItemBackgroundColor:
          toolbarMenuItemBackgroundColor ?? this.toolbarMenuItemBackgroundColor,
      toolbarMenuItemSelectedBackgroundColor:
          toolbarMenuItemSelectedBackgroundColor ??
              this.toolbarMenuItemSelectedBackgroundColor,
      toolbarMenuIconColor: toolbarMenuIconColor ?? this.toolbarMenuIconColor,
      toolbarMenuIconDisabledColor:
          toolbarMenuIconDisabledColor ?? this.toolbarMenuIconDisabledColor,
      toolbarMenuIconSelectedColor:
          toolbarMenuIconSelectedColor ?? this.toolbarMenuIconSelectedColor,
      toolbarShadowColor: toolbarShadowColor ?? this.toolbarShadowColor,
    );
  }

  @override
  ToolbarColorExtension lerp(ToolbarColorExtension? other, double t) {
    if (other is! ToolbarColorExtension) {
      return this;
    }
    return ToolbarColorExtension(
      toolbarBackgroundColor:
          Color.lerp(toolbarBackgroundColor, other.toolbarBackgroundColor, t)!,
      toolbarItemIconColor:
          Color.lerp(toolbarItemIconColor, other.toolbarItemIconColor, t)!,
      toolbarItemIconDisabledColor: Color.lerp(
        toolbarItemIconDisabledColor,
        other.toolbarItemIconDisabledColor,
        t,
      )!,
      toolbarItemIconSelectedColor: Color.lerp(
        toolbarItemIconSelectedColor,
        other.toolbarItemIconSelectedColor,
        t,
      )!,
      toolbarItemSelectedBackgroundColor: Color.lerp(
        toolbarItemSelectedBackgroundColor,
        other.toolbarItemSelectedBackgroundColor,
        t,
      )!,
      toolbarMenuBackgroundColor: Color.lerp(
        toolbarMenuBackgroundColor,
        other.toolbarMenuBackgroundColor,
        t,
      )!,
      toolbarMenuItemBackgroundColor: Color.lerp(
        toolbarMenuItemBackgroundColor,
        other.toolbarMenuItemBackgroundColor,
        t,
      )!,
      toolbarMenuItemSelectedBackgroundColor: Color.lerp(
        toolbarMenuItemSelectedBackgroundColor,
        other.toolbarMenuItemSelectedBackgroundColor,
        t,
      )!,
      toolbarMenuIconColor:
          Color.lerp(toolbarMenuIconColor, other.toolbarMenuIconColor, t)!,
      toolbarMenuIconDisabledColor: Color.lerp(
        toolbarMenuIconDisabledColor,
        other.toolbarMenuIconDisabledColor,
        t,
      )!,
      toolbarMenuIconSelectedColor: Color.lerp(
        toolbarMenuIconSelectedColor,
        other.toolbarMenuIconSelectedColor,
        t,
      )!,
      toolbarShadowColor:
          Color.lerp(toolbarShadowColor, other.toolbarShadowColor, t)!,
    );
  }
}
