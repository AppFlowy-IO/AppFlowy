library document_plugin;

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/document/document_page.dart';
import 'package:app_flowy/plugins/document/presentation/more/more_button.dart';
import 'package:app_flowy/plugins/document/presentation/share/share_button.dart';
import 'package:app_flowy/plugins/util.dart';
import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DocumentPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return DocumentPlugin(pluginType: pluginType, view: data);
    } else {
      throw FlowyPluginException.invalidData;
    }
  }

  @override
  String get menuName => LocaleKeys.document_menuName.tr();

  @override
  String get menuIcon => "editor/documents";

  @override
  PluginType get pluginType => PluginType.editor;

  @override
  ViewDataFormatPB get dataFormatType => ViewDataFormatPB.TreeFormat;
}

class DocumentStyle with ChangeNotifier {
  DocumentStyle();

  double _fontSize = 14.0;
  double get fontSize => _fontSize;
  set fontSize(double fontSize) {
    _fontSize = fontSize;
    notifyListeners();
  }
}

class DocumentPlugin extends Plugin<int> {
  late PluginType _pluginType;
  late final DocumentStyle _documentStyle;

  @override
  final ViewPluginNotifier notifier;

  DocumentPlugin({
    required PluginType pluginType,
    required ViewPB view,
    Key? key,
  }) : notifier = ViewPluginNotifier(view: view) {
    _pluginType = pluginType;
    _documentStyle = DocumentStyle();
  }

  @override
  void dispose() {
    _documentStyle.dispose();
    super.dispose();
  }

  @override
  PluginDisplay get display {
    return DocumentPluginDisplay(
      notifier: notifier,
      documentStyle: _documentStyle,
    );
  }

  @override
  PluginType get ty => _pluginType;

  @override
  PluginId get id => notifier.view.id;
}

class DocumentPluginDisplay extends PluginDisplay with NavigationItem {
  final ViewPluginNotifier notifier;
  ViewPB get view => notifier.view;
  int? deletedViewIndex;
  DocumentStyle documentStyle;

  DocumentPluginDisplay({
    required this.notifier,
    required this.documentStyle,
    Key? key,
  });

  @override
  Widget buildWidget(PluginContext context) {
    notifier.isDeleted.addListener(() {
      notifier.isDeleted.value.fold(() => null, (deletedView) {
        if (deletedView.hasIndex()) {
          deletedViewIndex = deletedView.index;
        }
      });
    });

    return ChangeNotifierProvider.value(
      value: documentStyle,
      child: DocumentPage(
        view: view,
        onDeleted: () => context.onDeleted(view, deletedViewIndex),
        key: ValueKey(view.id),
      ),
    );
  }

  @override
  Widget get leftBarItem => ViewLeftBarItem(view: view);

  @override
  Widget? get rightBarItem {
    return Row(
      children: [
        DocumentShareButton(view: view),
        const SizedBox(width: 10),
        ChangeNotifierProvider.value(
          value: documentStyle,
          child: const DocumentMoreButton(),
        ),
      ],
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}

extension QuestionBubbleExtension on ShareAction {
  String get name {
    switch (this) {
      case ShareAction.markdown:
        return LocaleKeys.shareAction_markdown.tr();
      case ShareAction.copyLink:
        return LocaleKeys.shareAction_copyLink.tr();
    }
  }
}
