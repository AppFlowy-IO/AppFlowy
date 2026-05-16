import 'dart:convert';

import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('space_icon.dart', () {
    testWidgets('space icon is empty', (WidgetTester tester) async {
      final emptySpaceIcon = {
        ViewExtKeys.spaceIconKey: '',
        ViewExtKeys.spaceIconColorKey: '',
      };
      final space = ViewPB(
        name: 'test',
        extra: jsonEncode(emptySpaceIcon),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SpaceIcon(dimension: 22, space: space),
          ),
        ),
      );

      // test that the input field exists
      expect(find.byType(SpaceIcon), findsOneWidget);

      // use the first character of page name as icon
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('space icon is null', (WidgetTester tester) async {
      final emptySpaceIcon = {
        ViewExtKeys.spaceIconKey: null,
        ViewExtKeys.spaceIconColorKey: null,
      };
      final space = ViewPB(
        name: 'test',
        extra: jsonEncode(emptySpaceIcon),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SpaceIcon(dimension: 22, space: space),
          ),
        ),
      );

      expect(find.byType(SpaceIcon), findsOneWidget);

      // use the first character of page name as icon
      expect(find.text('T'), findsOneWidget);
    });
  });
}
