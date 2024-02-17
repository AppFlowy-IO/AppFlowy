library document_plugin;

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/document_page.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/more/more_button.dart';
import 'package:appflowy/plugins/document/presentation/share/share_button.dart';
import 'package:appflowy/plugins/document/presentation/favorite/favorite_button.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return DocumentPlugin(pluginType: pluginType, view: data);
    }

    throw FlowyPluginException.invalidData;
  }

  @override
  String get menuName => LocaleKeys.document_menuName.tr();

  @override
  FlowySvgData get icon => FlowySvgs.document_s;

  @override
  PluginType get pluginType => PluginType.editor;

  @override
  ViewLayoutPB? get layoutType => ViewLayoutPB.Document;
}

class DocumentPlugin extends Plugin<int> {
  DocumentPlugin({
    required ViewPB view,
    required PluginType pluginType,
    this.initialSelection,
  }) : notifier = ViewPluginNotifier(view: view) {
    _pluginType = pluginType;
  }

  late PluginType _pluginType;

  @override
  final ViewPluginNotifier notifier;

  final Selection? initialSelection;

  @override
  PluginWidgetBuilder get widgetBuilder => DocumentPluginWidgetBuilder(
        notifier: notifier,
        initialSelection: initialSelection,
      );

  @override
  PluginType get pluginType => _pluginType;

  @override
  PluginId get id => notifier.view.id;
}

class DocumentPluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  DocumentPluginWidgetBuilder({
    required this.notifier,
    this.initialSelection,
  });

  final ViewPluginNotifier notifier;
  ViewPB get view => notifier.view;
  int? deletedViewIndex;
  final Selection? initialSelection;

  @override
  EdgeInsets get contentPadding => EdgeInsets.zero;

  @override
  Widget buildWidget({PluginContext? context, required bool shrinkWrap}) {
    notifier.isDeleted.addListener(() {
      notifier.isDeleted.value.fold(
        () => null,
        (deletedView) {
          if (deletedView.hasIndex()) {
            deletedViewIndex = deletedView.index;
          }
        },
      );
    });

    return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
      builder: (_, state) => DocumentPage(
        key: ValueKey(view.id),
        view: view,
        onDeleted: () => context?.onDeleted(view, deletedViewIndex),
        initialSelection: initialSelection,
      ),
    );
  }

  @override
  Widget get leftBarItem => ViewTitleBar(view: view);

  @override
  Widget tabBarItem(String pluginId) => ViewTabBarItem(view: notifier.view);

  @override
  Widget? get rightBarItem {
    return Row(
      children: [
        DocumentShareButton(key: ValueKey(view.id), view: view),
        const HSpace(4),
        DocumentFavoriteButton(
          key: ValueKey('favorite_button_${view.id}'),
          view: view,
        ),
        const HSpace(4),
        const DocumentMoreButton(),
      ],
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}
