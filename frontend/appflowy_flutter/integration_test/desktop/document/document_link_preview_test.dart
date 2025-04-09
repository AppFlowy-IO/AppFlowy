import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_hover_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const avaliableLink = 'https://appflowy.io/';

  Future<void> preparePage(WidgetTester tester, {String? pageName}) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    await tester.createNewPageWithNameUnderParent(name: pageName);
    await tester.editor.tapLineOfEditorAt(0);
  }

  Future<void> pasteLink(WidgetTester tester, String link) async {
    await getIt<ClipboardService>()
        .setData(ClipboardServiceData(plainText: link));

    /// paste the link
    await tester.simulateKeyEvent(
      LogicalKeyboardKey.keyV,
      isControlPressed: Platform.isLinux || Platform.isWindows,
      isMetaPressed: Platform.isMacOS,
    );
    await tester.pumpAndSettle(Duration(seconds: 1));
  }

  Future<void> pasteAndTurnInto(
    WidgetTester tester,
    String link,
    String title,
  ) async {
    await pasteLink(tester, link);
    final convertToLinkButton = find
        .text(LocaleKeys.document_plugins_linkPreview_typeSelection_URL.tr());
    await tester.tapButton(convertToLinkButton);

    /// hover link and turn into mention
    await tester.hoverOnWidget(
      find.byType(LinkHoverTrigger),
      onHover: () async {
        final turnintoButton = find.byFlowySvg(FlowySvgs.turninto_m);
        await tester.tapButton(turnintoButton);
        final convertToButton = find.text(title);
        await tester.tapButton(convertToButton);
        await tester.pumpAndSettle(Duration(seconds: 1));
      },
    );
  }

  void checkUrl(Node node, String link) {
    expect(node.type, ParagraphBlockKeys.type);
    expect(node.delta!.toJson(), [
      {
        'insert': link,
        'attributes': {'href': link},
      }
    ]);
  }

  void checkMention(Node node, String link) {
    final delta = node.delta!;
    final insert = (delta.first as TextInsert).text;
    final attributes = delta.first.attributes;
    expect(insert, MentionBlockKeys.mentionChar);
    final mention =
        attributes?[MentionBlockKeys.mention] as Map<String, dynamic>;
    expect(mention[MentionBlockKeys.type], MentionType.externalLink.name);
    expect(mention[MentionBlockKeys.url], avaliableLink);
  }

  void checkBookmark(Node node, String link) {
    expect(node.type, LinkPreviewBlockKeys.type);
    expect(node.attributes[LinkPreviewBlockKeys.url], link);
  }

  void checkEmbed(Node node, String link) {
    expect(node.type, LinkPreviewBlockKeys.type);
    expect(node.attributes[LinkEmbedKeys.previewType], LinkEmbedKeys.embed);
    expect(node.attributes[LinkPreviewBlockKeys.url], link);
  }

  group('Paste as URL', () {
    testWidgets('paste a link text', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteLink(tester, link);
      final convertToLinkButton = find
          .text(LocaleKeys.document_plugins_linkPreview_typeSelection_URL.tr());
      await tester.tapButton(convertToLinkButton);
      final node = tester.editor.getNodeAtPath([0]);
      checkUrl(node, link);
    });

    testWidgets('paste a link and turn into mention', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAndTurnInto(
        tester,
        link,
        LinkConvertMenuCommand.toMention.title,
      );

      /// check metion values
      final node = tester.editor.getNodeAtPath([0]);
      checkMention(node, link);
    });

    testWidgets('paste a link and turn into bookmark', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAndTurnInto(
        tester,
        link,
        LinkConvertMenuCommand.toBookmark.title,
      );

      /// check metion values
      final node = tester.editor.getNodeAtPath([0]);
      checkBookmark(node, link);
    });

    testWidgets('paste a link and turn into embed', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAndTurnInto(
        tester,
        link,
        LinkConvertMenuCommand.toEmbed.title,
      );

      /// check metion values
      final node = tester.editor.getNodeAtPath([0]);
      checkEmbed(node, link);
    });
  });

  group('Paste as Mention', () {});

  group('Paste as Bookmark', () {});
  group('Paste as Embed', () {});
}
