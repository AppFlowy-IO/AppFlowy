library document_plugin;

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'database_document_page.dart';
import 'presentation/database_document_title.dart';

// This widget is largely copied from `plugins/document/document_plugin.dart` intentionally instead of opting for an abstraction. We can make an abstraction after the view refactor is done and there's more clarity in that department.

class DatabaseDocumentContext {
  DatabaseDocumentContext({
    required this.view,
    required this.databaseId,
    required this.rowId,
    required this.documentId,
  });

  final ViewPB view;
  final String databaseId;
  final String rowId;
  final String documentId;
}

class DatabaseDocumentPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is DatabaseDocumentContext) {
      return DatabaseDocumentPlugin(pluginType: pluginType, data: data);
    }

    throw FlowyPluginException.invalidData;
  }

  @override
  String get menuName => LocaleKeys.document_menuName.tr();

  @override
  FlowySvgData get icon => FlowySvgs.icon_document_s;

  @override
  PluginType get pluginType => PluginType.databaseDocument;
}

class DatabaseDocumentPlugin extends Plugin {
  DatabaseDocumentPlugin({
    required this.data,
    required PluginType pluginType,
    this.initialSelection,
  }) : _pluginType = pluginType;

  final DatabaseDocumentContext data;
  final PluginType _pluginType;

  final Selection? initialSelection;

  @override
  PluginWidgetBuilder get widgetBuilder => DatabaseDocumentPluginWidgetBuilder(
        view: data.view,
        databaseId: data.databaseId,
        rowId: data.rowId,
        documentId: data.documentId,
        initialSelection: initialSelection,
      );

  @override
  PluginType get pluginType => _pluginType;

  @override
  PluginId get id => data.rowId;
}

class DatabaseDocumentPluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  DatabaseDocumentPluginWidgetBuilder({
    required this.view,
    required this.databaseId,
    required this.rowId,
    required this.documentId,
    this.initialSelection,
  });

  final ViewPB view;
  final String databaseId;
  final String rowId;
  final String documentId;
  final Selection? initialSelection;

  @override
  EdgeInsets get contentPadding => EdgeInsets.zero;

  @override
  Widget buildWidget({PluginContext? context, required bool shrinkWrap}) {
    return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
      builder: (_, state) => DatabaseDocumentPage(
        key: ValueKey(documentId),
        view: view,
        databaseId: databaseId,
        documentId: documentId,
        rowId: rowId,
        initialSelection: initialSelection,
      ),
    );
  }

  @override
  Widget get leftBarItem =>
      ViewTitleBarWithRow(view: view, databaseId: databaseId, rowId: rowId);

  @override
  Widget tabBarItem(String pluginId) => const SizedBox.shrink();

  @override
  Widget? get rightBarItem => const SizedBox.shrink();

  @override
  List<NavigationItem> get navigationItems => [this];
}

class DatabaseDocumentPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}
