import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/ai_chat/chat.dart';
import 'package:appflowy/plugins/database/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/mobile_grid_page.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/document/document.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PluginArgumentKeys {
  static String selection = "selection";
  static String rowId = "row_id";
}

class ViewExtKeys {
  // used for customizing the font family.
  static String fontKey = 'font';

  // used for customizing the font layout.
  static String fontLayoutKey = 'font_layout';

  // used for customizing the line height layout.
  static String lineHeightLayoutKey = 'line_height_layout';

  // cover keys
  static String coverKey = 'cover';
  static String coverTypeKey = 'type';
  static String coverValueKey = 'value';

  // is pinned
  static String isPinnedKey = 'is_pinned';

  // space
  static String isSpaceKey = 'is_space';
  static String spaceCreatorKey = 'space_creator';
  static String spaceCreatedAtKey = 'space_created_at';
  static String spaceIconKey = 'space_icon';
  static String spaceIconColorKey = 'space_icon_color';
  static String spacePermissionKey = 'space_permission';
}

extension ViewExtension on ViewPB {
  Widget defaultIcon({Size? size}) => FlowySvg(
        switch (layout) {
          ViewLayoutPB.Board => FlowySvgs.icon_board_s,
          ViewLayoutPB.Calendar => FlowySvgs.icon_calendar_s,
          ViewLayoutPB.Grid => FlowySvgs.icon_grid_s,
          ViewLayoutPB.Document => FlowySvgs.icon_document_s,
          ViewLayoutPB.Chat => FlowySvgs.chat_ai_page_s,
          _ => FlowySvgs.document_s,
        },
        size: size,
      );

  PluginType get pluginType => switch (layout) {
        ViewLayoutPB.Board => PluginType.board,
        ViewLayoutPB.Calendar => PluginType.calendar,
        ViewLayoutPB.Document => PluginType.document,
        ViewLayoutPB.Grid => PluginType.grid,
        ViewLayoutPB.Chat => PluginType.chat,
        _ => throw UnimplementedError(),
      };

  Plugin plugin({
    Map<String, dynamic> arguments = const {},
  }) {
    switch (layout) {
      case ViewLayoutPB.Board:
      case ViewLayoutPB.Calendar:
      case ViewLayoutPB.Grid:
        final String? rowId = arguments[PluginArgumentKeys.rowId];

        return DatabaseTabBarViewPlugin(
          view: this,
          pluginType: pluginType,
          initialRowId: rowId,
        );
      case ViewLayoutPB.Document:
        final Selection? initialSelection =
            arguments[PluginArgumentKeys.selection];

        return DocumentPlugin(
          view: this,
          pluginType: pluginType,
          initialSelection: initialSelection,
        );
      case ViewLayoutPB.Chat:
        return AIChatPagePlugin(view: this);
    }
    throw UnimplementedError;
  }

  DatabaseTabBarItemBuilder tabBarItem() => switch (layout) {
        ViewLayoutPB.Board => BoardPageTabBarBuilderImpl(),
        ViewLayoutPB.Calendar => CalendarPageTabBarBuilderImpl(),
        ViewLayoutPB.Grid => DesktopGridTabBarBuilderImpl(),
        _ => throw UnimplementedError,
      };

  DatabaseTabBarItemBuilder mobileTabBarItem() => switch (layout) {
        ViewLayoutPB.Board => BoardPageTabBarBuilderImpl(),
        ViewLayoutPB.Calendar => CalendarPageTabBarBuilderImpl(),
        ViewLayoutPB.Grid => MobileGridTabBarBuilderImpl(),
        _ => throw UnimplementedError,
      };

  FlowySvgData get iconData => layout.icon;

  bool get isSpace {
    try {
      if (extra.isEmpty) {
        return false;
      }

      final ext = jsonDecode(extra);
      final isSpace = ext[ViewExtKeys.isSpaceKey] ?? false;
      return isSpace;
    } catch (e) {
      return false;
    }
  }

  SpacePermission get spacePermission {
    try {
      final ext = jsonDecode(extra);
      final permission = ext[ViewExtKeys.spacePermissionKey] ?? 1;
      return SpacePermission.values[permission];
    } catch (e) {
      return SpacePermission.private;
    }
  }

  FlowySvg? buildSpaceIconSvg(BuildContext context, {Size? size}) {
    try {
      if (extra.isEmpty) {
        return null;
      }

      final ext = jsonDecode(extra);
      final icon = ext[ViewExtKeys.spaceIconKey];
      final color = ext[ViewExtKeys.spaceIconColorKey];
      if (icon == null || color == null) {
        return null;
      }
      // before version 0.6.7
      if (icon.contains('space_icon')) {
        return FlowySvg(
          FlowySvgData('assets/flowy_icons/16x/$icon.svg'),
          color: Theme.of(context).colorScheme.surface,
        );
      }

      final values = icon.split('/');
      if (values.length != 2) {
        return null;
      }
      final groupName = values[0];
      final iconName = values[1];
      final svgString = kIconGroups
          ?.firstWhereOrNull(
            (group) => group.name == groupName,
          )
          ?.icons
          .firstWhereOrNull(
            (icon) => icon.name == iconName,
          )
          ?.content;
      if (svgString == null) {
        return null;
      }
      return FlowySvg.string(
        svgString,
        color: Theme.of(context).colorScheme.surface,
        size: size,
      );
    } catch (e) {
      return null;
    }
  }

  String? get spaceIcon {
    try {
      final ext = jsonDecode(extra);
      final icon = ext[ViewExtKeys.spaceIconKey];
      return icon;
    } catch (e) {
      return null;
    }
  }

  String? get spaceIconColor {
    try {
      final ext = jsonDecode(extra);
      final color = ext[ViewExtKeys.spaceIconColorKey];
      return color;
    } catch (e) {
      return null;
    }
  }

  bool get isPinned {
    try {
      final ext = jsonDecode(extra);
      final isPinned = ext[ViewExtKeys.isPinnedKey] ?? false;
      return isPinned;
    } catch (e) {
      return false;
    }
  }

  PageStyleCover? get cover {
    if (layout != ViewLayoutPB.Document) {
      return null;
    }

    if (extra.isEmpty) {
      return null;
    }

    try {
      final ext = jsonDecode(extra);
      final cover = ext[ViewExtKeys.coverKey] ?? {};
      final coverType = cover[ViewExtKeys.coverTypeKey] ??
          PageStyleCoverImageType.none.toString();
      final coverValue = cover[ViewExtKeys.coverValueKey] ?? '';
      return PageStyleCover(
        type: PageStyleCoverImageType.fromString(coverType),
        value: coverValue,
      );
    } catch (e) {
      return null;
    }
  }

  PageStyleLineHeightLayout get lineHeightLayout {
    if (layout != ViewLayoutPB.Document) {
      return PageStyleLineHeightLayout.normal;
    }
    try {
      final ext = jsonDecode(extra);
      final lineHeight = ext[ViewExtKeys.lineHeightLayoutKey];
      return PageStyleLineHeightLayout.fromString(lineHeight);
    } catch (e) {
      return PageStyleLineHeightLayout.normal;
    }
  }

  PageStyleFontLayout get fontLayout {
    if (layout != ViewLayoutPB.Document) {
      return PageStyleFontLayout.normal;
    }
    try {
      final ext = jsonDecode(extra);
      final fontLayout = ext[ViewExtKeys.fontLayoutKey];
      return PageStyleFontLayout.fromString(fontLayout);
    } catch (e) {
      return PageStyleFontLayout.normal;
    }
  }
}

extension ViewLayoutExtension on ViewLayoutPB {
  FlowySvgData get icon => switch (this) {
        ViewLayoutPB.Grid => FlowySvgs.grid_s,
        ViewLayoutPB.Board => FlowySvgs.board_s,
        ViewLayoutPB.Calendar => FlowySvgs.calendar_s,
        ViewLayoutPB.Document => FlowySvgs.document_s,
        ViewLayoutPB.Chat => FlowySvgs.chat_ai_page_s,
        _ => throw Exception('Unknown layout type'),
      };

  FlowySvgData mentionIcon({bool isChildPage = false}) => switch (this) {
        ViewLayoutPB.Document =>
          isChildPage ? FlowySvgs.child_page_s : FlowySvgs.link_to_page_s,
        _ => icon,
      };

  bool get isDocumentView => switch (this) {
        ViewLayoutPB.Document => true,
        ViewLayoutPB.Chat ||
        ViewLayoutPB.Grid ||
        ViewLayoutPB.Board ||
        ViewLayoutPB.Calendar =>
          false,
        _ => throw Exception('Unknown layout type'),
      };

  bool get isDatabaseView => switch (this) {
        ViewLayoutPB.Grid ||
        ViewLayoutPB.Board ||
        ViewLayoutPB.Calendar =>
          true,
        ViewLayoutPB.Document || ViewLayoutPB.Chat => false,
        _ => throw Exception('Unknown layout type'),
      };

  String get defaultName => switch (this) {
        ViewLayoutPB.Document => '',
        _ => LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
      };
}

extension ViewFinder on List<ViewPB> {
  ViewPB? findView(String id) {
    for (final view in this) {
      if (view.id == id) {
        return view;
      }

      if (view.childViews.isNotEmpty) {
        final v = view.childViews.findView(id);
        if (v != null) {
          return v;
        }
      }
    }

    return null;
  }
}
