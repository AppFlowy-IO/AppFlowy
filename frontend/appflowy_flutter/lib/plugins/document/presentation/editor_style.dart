import 'package:appflowy/plugins/document/presentation/editor_plugins/inline_page/inline_page_reference.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide FlowySvg, Log;
import 'package:collection/collection.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class EditorStyleCustomizer {
  EditorStyleCustomizer({
    required this.context,
    required this.padding,
  });

  final BuildContext context;
  final EdgeInsets padding;

  EditorStyle style() {
    if (PlatformExtension.isDesktopOrWeb) {
      return desktop();
    } else if (PlatformExtension.isMobile) {
      return mobile();
    }
    throw UnimplementedError();
  }

  EditorStyle desktop() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    return EditorStyle.desktop(
      padding: padding,
      backgroundColor: theme.colorScheme.surface,
      cursorColor: theme.colorScheme.primary,
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          fontFamily: 'Poppins',
          fontSize: fontSize,
          color: theme.colorScheme.onBackground,
          height: 1.5,
        ),
        bold: const TextStyle(
          fontFamily: 'Poppins-Bold',
          fontWeight: FontWeight.w600,
        ),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
        href: TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: GoogleFonts.robotoMono(
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: Colors.red,
            backgroundColor: theme.colorScheme.inverseSurface,
          ),
        ),
      ),
      textSpanDecorator: customizeAttributeDecorator,
    );
  }

  EditorStyle mobile() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    return EditorStyle.desktop(
      padding: padding,
      backgroundColor: theme.colorScheme.surface,
      cursorColor: theme.colorScheme.primary,
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          fontFamily: 'poppins',
          fontSize: fontSize,
          color: theme.colorScheme.onBackground,
          height: 1.5,
        ),
        bold: const TextStyle(
          fontFamily: 'poppins-Bold',
          fontWeight: FontWeight.w600,
        ),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
        href: TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: GoogleFonts.robotoMono(
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: Colors.red,
            backgroundColor: theme.colorScheme.inverseSurface,
          ),
        ),
      ),
    );
  }

  TextStyle headingStyleBuilder(int level) {
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    final fontSizes = [
      fontSize + 16,
      fontSize + 12,
      fontSize + 8,
      fontSize + 4,
      fontSize + 2,
      fontSize
    ];
    return TextStyle(
      fontSize: fontSizes.elementAtOrNull(level - 1) ?? fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle codeBlockStyleBuilder() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    return TextStyle(
      fontFamily: 'poppins',
      fontSize: fontSize,
      height: 1.5,
      color: theme.colorScheme.onBackground,
    );
  }

  SelectionMenuStyle selectionMenuStyleBuilder() {
    final theme = Theme.of(context);
    return SelectionMenuStyle(
      selectionMenuBackgroundColor: theme.cardColor,
      selectionMenuItemTextColor: theme.colorScheme.onBackground,
      selectionMenuItemIconColor: theme.colorScheme.onBackground,
      selectionMenuItemSelectedIconColor: theme.colorScheme.onSurface,
      selectionMenuItemSelectedTextColor: theme.colorScheme.onSurface,
      selectionMenuItemSelectedColor: theme.hoverColor,
    );
  }

  FloatingToolbarStyle floatingToolbarStyleBuilder() {
    final theme = Theme.of(context);
    return FloatingToolbarStyle(
      backgroundColor: theme.colorScheme.onTertiary,
    );
  }

  InlineSpan customizeAttributeDecorator(
    TextInsert textInsert,
    TextSpan textSpan,
  ) {
    final attributes = textInsert.attributes;
    if (attributes == null) {
      return textSpan;
    }
    final mention = attributes[MentionBlockKeys.mention] as Map?;
    if (mention != null) {
      final type = mention[MentionBlockKeys.type];
      if (type == MentionType.page.name) {
        return WidgetSpan(
          child: MentionBlock(
            mention: mention,
          ),
        );
      }
    }
    return textSpan;
  }
}

class MentionBlock extends StatelessWidget {
  const MentionBlock({
    super.key,
    required this.mention,
  });

  final Map mention;

  @override
  Widget build(BuildContext context) {
    final type = mention[MentionBlockKeys.type];
    if (type == MentionType.page.name) {
      final pageName = mention[MentionBlockKeys.pageName];
      final pageId = mention[MentionBlockKeys.pageId];
      final layout = layoutFromName(mention[MentionBlockKeys.pageType]);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FlowyHover(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => openPage(layout, pageId),
            behavior: HitTestBehavior.translucent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HSpace(4),
                FlowySvg(
                  name: layout.iconName,
                  size: const Size.square(18.0),
                ),
                const HSpace(2),
                FlowyText(
                  pageName,
                  decoration: TextDecoration.underline,
                ),
                const HSpace(4),
              ],
            ),
          ),
        ),
      );
    }
    throw UnimplementedError();
  }

  void openPage(ViewLayoutPB layout, String pageId) async {
    final views = await ViewBackendService().fetchViews(layout);
    final flattenViews = views.expand((e) => [e.$1, ...e.$2]).toList();
    final view = flattenViews.firstWhereOrNull(
      (element) => element.id == pageId,
    );
    if (view == null) {
      Log.error('Page($pageId) not found');
      return;
    }
    getIt<MenuSharedState>().latestOpenView = view;
  }

  ViewLayoutPB layoutFromName(String name) {
    if (name == ViewLayoutPB.Grid.name) {
      return ViewLayoutPB.Grid;
    } else if (name == ViewLayoutPB.Calendar.name) {
      return ViewLayoutPB.Calendar;
    } else if (name == ViewLayoutPB.Board.name) {
      return ViewLayoutPB.Board;
    } else if (name == ViewLayoutPB.Document.name) {
      return ViewLayoutPB.Document;
    } else {
      throw UnimplementedError();
    }
  }
}
