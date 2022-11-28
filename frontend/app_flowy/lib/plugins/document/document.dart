library document_plugin;

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/document/document_page.dart';
import 'package:app_flowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:app_flowy/plugins/document/presentation/more/more_button.dart';
import 'package:app_flowy/plugins/document/presentation/share/share_button.dart';
import 'package:app_flowy/plugins/util.dart';
import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class DocumentPlugin extends Plugin<int> {
  late PluginType _pluginType;
  late final DocumentAppearanceCubit _documentAppearanceCubit;

  @override
  final ViewPluginNotifier notifier;

  DocumentPlugin({
    required PluginType pluginType,
    required ViewPB view,
    Key? key,
  }) : notifier = ViewPluginNotifier(view: view) {
    _pluginType = pluginType;
    _documentAppearanceCubit = DocumentAppearanceCubit();
  }

  @override
  void dispose() {
    _documentAppearanceCubit.close();
    super.dispose();
  }

  @override
  PluginDisplay get display {
    return DocumentPluginDisplay(
      notifier: notifier,
      documentAppearanceCubit: _documentAppearanceCubit,
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
  DocumentAppearanceCubit documentAppearanceCubit;

  DocumentPluginDisplay({
    required this.notifier,
    required this.documentAppearanceCubit,
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

    return BlocProvider.value(
      value: documentAppearanceCubit,
      child: BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
        builder: (_, state) {
          return DocumentPage(
            view: view,
            onDeleted: () => context.onDeleted(view, deletedViewIndex),
            key: ValueKey(view.id),
          );
        },
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
        BlocProvider.value(
          value: documentAppearanceCubit,
          child: const DocumentMoreButton(),
        ),
      ],
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}
