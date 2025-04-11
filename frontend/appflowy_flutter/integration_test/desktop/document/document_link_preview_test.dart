import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_hover_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_preview_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/link_preview_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/paste_as/paste_as_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_link_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_link_error_preview.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_link_preview.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const avaliableLink = 'https://appflowy.io/',
      unavailableLink = 'www.thereIsNoting.com';

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

  Future<void> pasteAs(
    WidgetTester tester,
    String link,
    PasteMenuType type, {
    Duration waitTime = const Duration(milliseconds: 500),
  }) async {
    await pasteLink(tester, link);
    final convertToMentionButton = find.text(type.title);
    await tester.tapButton(convertToMentionButton);
    await tester.pumpAndSettle(waitTime);
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

    testWidgets('paste a link', (tester) async {
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

  group('Paste as Mention', () {
    Future<void> pasteAsMention(WidgetTester tester, String link) =>
        pasteAs(tester, link, PasteMenuType.mention);

    String getMentionLink(Node node) {
      final insert = node.delta?.first as TextInsert?;
      final mention = insert?.attributes?[MentionBlockKeys.mention]
          as Map<String, dynamic>?;
      return mention?[MentionBlockKeys.url] ?? '';
    }

    Future<void> hoverMentionAndClick(
      WidgetTester tester,
      String command,
    ) async {
      final mentionLink = find.byType(MentionLinkBlock);
      expect(mentionLink, findsOneWidget);
      await tester.hoverOnWidget(
        mentionLink,
        onHover: () async {
          final errorPreview = find.byType(MentionLinkErrorPreview);
          expect(errorPreview, findsOneWidget);
          final convertButton = find.byFlowySvg(FlowySvgs.turninto_m);
          await tester.tapButton(convertButton);
          final menuButton = find.text(command);
          await tester.tapButton(menuButton);
        },
      );
    }

    testWidgets('paste a link as mention', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsMention(tester, link);
      final node = tester.editor.getNodeAtPath([0]);
      checkMention(node, link);
    });

    testWidgets('paste as mention and copy link', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsMention(tester, link);
      final mentionLink = find.byType(MentionLinkBlock);
      expect(mentionLink, findsOneWidget);
      await tester.hoverOnWidget(
        mentionLink,
        onHover: () async {
          final preview = find.byType(MentionLinkPreview);
          if (!preview.hasFound) {
            final copyButton = find.byFlowySvg(FlowySvgs.toolbar_link_m);
            await tester.tapButton(copyButton);
          } else {
            final moreOptionButton = find.byFlowySvg(FlowySvgs.toolbar_more_m);
            await tester.tapButton(moreOptionButton);
            final copyButton =
                find.text(MentionLinktMenuCommand.copyLink.title);
            await tester.tapButton(copyButton);
          }
        },
      );
      final clipboardContent = await getIt<ClipboardService>().getData();
      expect(clipboardContent.plainText, link);
    });

    testWidgets('paste as error mention and turninto url', (tester) async {
      String link = unavailableLink;
      await preparePage(tester);
      await pasteAsMention(tester, link);
      Node node = tester.editor.getNodeAtPath([0]);
      link = getMentionLink(node);
      await hoverMentionAndClick(
        tester,
        MentionLinktErrorMenuCommand.toURL.title,
      );
      node = tester.editor.getNodeAtPath([0]);
      checkUrl(node, link);
    });

    testWidgets('paste as error mention and turninto embed', (tester) async {
      String link = unavailableLink;
      await preparePage(tester);
      await pasteAsMention(tester, link);
      Node node = tester.editor.getNodeAtPath([0]);
      link = getMentionLink(node);
      await hoverMentionAndClick(
        tester,
        MentionLinktErrorMenuCommand.toEmbed.title,
      );
      node = tester.editor.getNodeAtPath([0]);
      checkEmbed(node, link);
    });

    testWidgets('paste as error mention and turninto bookmark', (tester) async {
      String link = unavailableLink;
      await preparePage(tester);
      await pasteAsMention(tester, link);
      Node node = tester.editor.getNodeAtPath([0]);
      link = getMentionLink(node);
      await hoverMentionAndClick(
        tester,
        MentionLinktErrorMenuCommand.toBookmark.title,
      );
      node = tester.editor.getNodeAtPath([0]);
      checkBookmark(node, link);
    });

    testWidgets('paste as error mention and remove link', (tester) async {
      String link = unavailableLink;
      await preparePage(tester);
      await pasteAsMention(tester, link);
      Node node = tester.editor.getNodeAtPath([0]);
      link = getMentionLink(node);
      await hoverMentionAndClick(
        tester,
        MentionLinktErrorMenuCommand.removeLink.title,
      );
      node = tester.editor.getNodeAtPath([0]);
      expect(node.type, ParagraphBlockKeys.type);
      expect(node.delta!.toJson(), [
        {'insert': link},
      ]);
    });
  });

  group('Paste as Bookmark', () {
    Future<void> pasteAsBookmark(WidgetTester tester, String link) =>
        pasteAs(tester, link, PasteMenuType.bookmark);

    Future<void> hoverAndClick(
      WidgetTester tester,
      LinkPreviewMenuCommand command,
    ) async {
      final bookmark = find.byType(CustomLinkPreviewBlockComponent);
      expect(bookmark, findsOneWidget);
      await tester.hoverOnWidget(
        bookmark,
        onHover: () async {
          final menuButton = find.byFlowySvg(FlowySvgs.toolbar_more_m);
          await tester.tapButton(menuButton);
          final commandButton = find.text(command.title);
          await tester.tapButton(commandButton);
        },
      );
    }

    testWidgets('paste a link as bookmark', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsBookmark(tester, link);
      final node = tester.editor.getNodeAtPath([0]);
      checkBookmark(node, link);
    });

    testWidgets('paste a link as bookmark and convert to mention',
        (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsBookmark(tester, link);
      await hoverAndClick(tester, LinkPreviewMenuCommand.convertToMention);
      final node = tester.editor.getNodeAtPath([0]);
      checkMention(node, link);
    });

    testWidgets('paste a link as bookmark and convert to url', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsBookmark(tester, link);
      await hoverAndClick(tester, LinkPreviewMenuCommand.convertToUrl);
      final node = tester.editor.getNodeAtPath([0]);
      checkUrl(node, link);
    });

    testWidgets('paste a link as bookmark and convert to embed',
        (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsBookmark(tester, link);
      await hoverAndClick(tester, LinkPreviewMenuCommand.convertToEmbed);
      final node = tester.editor.getNodeAtPath([0]);
      checkEmbed(node, link);
    });

    testWidgets('paste a link as bookmark and copy link', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsBookmark(tester, link);
      await hoverAndClick(tester, LinkPreviewMenuCommand.copyLink);
      final clipboardContent = await getIt<ClipboardService>().getData();
      expect(clipboardContent.plainText, link);
    });

    testWidgets('paste a link as bookmark and replace link', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsBookmark(tester, link);
      await hoverAndClick(tester, LinkPreviewMenuCommand.replace);
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyA,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.simulateKeyEvent(LogicalKeyboardKey.delete);
      await tester.enterText(find.byType(TextFormField), unavailableLink);
      await tester.tapButton(find.text(LocaleKeys.button_replace.tr()));
      final node = tester.editor.getNodeAtPath([0]);
      checkBookmark(node, unavailableLink);
    });

    testWidgets('paste a link as bookmark and remove link', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsBookmark(tester, link);
      await hoverAndClick(tester, LinkPreviewMenuCommand.removeLink);
      final node = tester.editor.getNodeAtPath([0]);
      expect(node.type, ParagraphBlockKeys.type);
      expect(node.delta!.toJson(), [
        {'insert': link},
      ]);
    });
  });
  group('Paste as Embed', () {
    Future<void> pasteAsEmbed(WidgetTester tester, String link) =>
        pasteAs(tester, link, PasteMenuType.embed);

    Future<void> hoverAndConvert(
      WidgetTester tester,
      LinkEmbedConvertCommand command,
    ) async {
      final embed = find.byType(LinkEmbedBlockComponent);
      expect(embed, findsOneWidget);
      await tester.hoverOnWidget(
        embed,
        onHover: () async {
          final menuButton = find.byFlowySvg(FlowySvgs.turninto_m);
          await tester.tapButton(menuButton);
          final commandButton = find.text(command.title);
          await tester.tapButton(commandButton);
        },
      );
    }

    testWidgets('paste a link as embed', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsEmbed(tester, link);
      final node = tester.editor.getNodeAtPath([0]);
      checkEmbed(node, link);
    });

    testWidgets('paste a link as bookmark and convert to mention',
        (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsEmbed(tester, link);
      await hoverAndConvert(tester, LinkEmbedConvertCommand.toMention);
      final node = tester.editor.getNodeAtPath([0]);
      checkMention(node, link);
    });

    testWidgets('paste a link as bookmark and convert to url', (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsEmbed(tester, link);
      await hoverAndConvert(tester, LinkEmbedConvertCommand.toURL);
      final node = tester.editor.getNodeAtPath([0]);
      checkUrl(node, link);
    });

    testWidgets('paste a link as bookmark and convert to bookmark',
        (tester) async {
      final link = avaliableLink;
      await preparePage(tester);
      await pasteAsEmbed(tester, link);
      await hoverAndConvert(tester, LinkEmbedConvertCommand.toBookmark);
      final node = tester.editor.getNodeAtPath([0]);
      checkBookmark(node, link);
    });
  });
}
