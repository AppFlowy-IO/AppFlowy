import 'dart:convert';

import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_color_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension EmojiTestExtension on WidgetTester {
  Future<void> tapEmoji(String emoji) async {
    final emojiWidget = find.descendant(
      of: find.byType(EmojiPicker),
      matching: find.text(emoji),
    );
    await tapButton(emojiWidget);
  }

  Future<void> tapIcon(EmojiIconData icon, {bool enableColor = true}) async {
    final iconsData = IconsData.fromJson(jsonDecode(icon.emoji));
    final pickTab = find.byType(PickerTab);
    expect(pickTab, findsOneWidget);
    await pumpAndSettle();
    final iconTab = find.descendant(
      of: pickTab,
      matching: find.text(PickerTabType.icon.tr),
    );
    expect(iconTab, findsOneWidget);
    await tapButton(iconTab);
    final selectedSvg = find.descendant(
      of: find.byType(FlowyIconPicker),
      matching: find.byWidgetPredicate(
        (w) => w is FlowySvg && w.svgString == iconsData.svgString,
      ),
    );

    await tapButton(selectedSvg.first);
    if (enableColor) {
      final colorPicker = find.byType(IconColorPicker);
      expect(colorPicker, findsOneWidget);
      final selectedColor = find.descendant(
        of: colorPicker,
        matching: find.byWidgetPredicate((w) {
          if (w is Container) {
            final d = w.decoration;
            if (d is ShapeDecoration) {
              if (d.color ==
                  Color(
                    int.parse(iconsData.color ?? builtInSpaceColors.first),
                  )) {
                return true;
              }
            }
          }
          return false;
        }),
      );
      await tapButton(selectedColor);
    }
  }
}
