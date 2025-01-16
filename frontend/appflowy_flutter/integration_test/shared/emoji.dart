import 'dart:convert';

import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_color_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_uploader.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flowy_infra_ui/style_widget/primary_rounded_button.dart';
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

  Future<void> tapIcon(EmojiIconData icon) async {
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
    final colorPicker = find.byType(IconColorPicker);
    expect(colorPicker, findsOneWidget);
    final selectedColor = find.descendant(
      of: colorPicker,
      matching: find.byWidgetPredicate((w) {
        if (w is Container) {
          final d = w.decoration;
          if (d is ShapeDecoration) {
            if (d.color ==
                Color(int.parse(iconsData.color ?? builtInSpaceColors.first))) {
              return true;
            }
          }
        }
        return false;
      }),
    );
    await tapButton(selectedColor);
  }

  Future<void> pickImage(EmojiIconData icon) async {
    final pickTab = find.byType(PickerTab);
    expect(pickTab, findsOneWidget);
    await pumpAndSettle();

    /// switch to custom tab
    final iconTab = find.descendant(
      of: pickTab,
      matching: find.text(PickerTabType.custom.tr),
    );
    expect(iconTab, findsOneWidget);
    await tapButton(iconTab);

    /// mock for dragging image
    final dropTarget = find.descendant(
      of: find.byType(IconUploader),
      matching: find.byType(DropTarget),
    );
    expect(dropTarget, findsOneWidget);
    final dropTargetWidget = dropTarget.evaluate().first.widget as DropTarget;
    dropTargetWidget.onDragDone?.call(
      DropDoneDetails(
        files: [XFile(icon.emoji)],
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ),
    );
    await pumpAndSettle(const Duration(seconds: 3));

    /// confirm to upload
    final confirmButton = find.descendant(
      of: find.byType(IconUploader),
      matching: find.byType(PrimaryRoundedButton),
    );
    await tapButton(confirmButton);
  }
}
