library docuemnt_plugin;

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/application/doc/share_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_listener.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/home/toast.dart';
import 'package:app_flowy/workspace/presentation/plugins/widgets/left_bar_item.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-text-block/entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'src/document_page.dart';

export './src/document_page.dart';
export './src/widget/toolbar/history_button.dart';
export './src/widget/toolbar/tool_bar.dart';
export './src/widget/toolbar/toolbar_icon_button.dart';

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
  PluginType get pluginType => DefaultPlugin.quill.type();

  @override
  ViewDataType get dataType => ViewDataType.TextBlock;
}

class DocumentPlugin implements Plugin {
  late ViewPB _view;
  ViewListener? _listener;
  late PluginType _pluginType;

  DocumentPlugin({required PluginType pluginType, required ViewPB view, Key? key}) : _view = view {
    _pluginType = pluginType;
    _listener = getIt<ViewListener>(param1: view);
    _listener?.start(onViewUpdated: (result) {
      result.fold(
        (newView) {
          _view = newView;
          display.notifier!.value = _view.hashCode;
        },
        (error) {},
      );
    });
  }

  @override
  void dispose() {
    _listener?.stop();
    _listener = null;
  }

  @override
  PluginDisplay<int> get display => DocumentPluginDisplay(view: _view);

  @override
  PluginType get ty => _pluginType;

  @override
  PluginId get id => _view.id;
}

class DocumentPluginDisplay extends PluginDisplay<int> with NavigationItem {
  final PublishNotifier<int> _displayNotifier = PublishNotifier<int>();
  final ViewPB _view;

  DocumentPluginDisplay({required ViewPB view, Key? key}) : _view = view;

  @override
  Widget buildWidget() => DocumentPage(view: _view, key: ValueKey(_view.id));

  @override
  Widget get leftBarItem => ViewLeftBarItem(view: _view);

  @override
  Widget? get rightBarItem => DocumentShareButton(view: _view);

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  PublishNotifier<int>? get notifier => _displayNotifier;
}

class DocumentShareButton extends StatelessWidget {
  final ViewPB view;
  DocumentShareButton({Key? key, required this.view}) : super(key: ValueKey(view.hashCode));

  @override
  Widget build(BuildContext context) {
    double buttonWidth = 60;
    return BlocProvider(
      create: (context) => getIt<DocShareBloc>(param1: view),
      child: BlocListener<DocShareBloc, DocShareState>(
        listener: (context, state) {
          state.map(
            initial: (_) {},
            loading: (_) {},
            finish: (state) {
              state.successOrFail.fold(
                _handleExportData,
                _handleExportError,
              );
            },
          );
        },
        child: BlocBuilder<DocShareBloc, DocShareState>(
          builder: (context, state) {
            return ChangeNotifierProvider.value(
              value: Provider.of<AppearanceSettingModel>(context, listen: true),
              child: Selector<AppearanceSettingModel, Locale>(
                selector: (ctx, notifier) => notifier.locale,
                builder: (ctx, _, child) => ConstrainedBox(
                  constraints: const BoxConstraints.expand(
                    height: 30,
                    // minWidth: buttonWidth,
                    width: 100,
                  ),
                  child: RoundedTextButton(
                    title: LocaleKeys.shareAction_buttonText.tr(),
                    fontSize: 12,
                    borderRadius: Corners.s6Border,
                    color: Colors.lightBlue,
                    onPressed: () => _showActionList(context, Offset(-(buttonWidth / 2), 10)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleExportData(ExportDataPB exportData) {
    switch (exportData.exportType) {
      case ExportType.Link:
        break;
      case ExportType.Markdown:
        FlutterClipboard.copy(exportData.data).then((value) => Log.info('copied to clipboard'));
        break;
      case ExportType.Text:
        break;
    }
  }

  void _handleExportError(FlowyError error) {}

  void _showActionList(BuildContext context, Offset offset) {
    final actionList = ShareActions(onSelected: (result) {
      result.fold(() {}, (action) {
        switch (action) {
          case ShareAction.markdown:
            context.read<DocShareBloc>().add(const DocShareEvent.shareMarkdown());
            showMessageToast('Exported to: ${LocaleKeys.notifications_export_path.tr()}');
            break;
          case ShareAction.copyLink:
            FlowyAlertDialog(title: LocaleKeys.shareAction_workInProgress.tr()).show(context);
            break;
        }
      });
    });
    actionList.show(
      context,
      anchorDirection: AnchorDirection.bottomWithCenterAligned,
      anchorOffset: offset,
    );
  }
}

class ShareActions with ActionList<ShareActionWrapper>, FlowyOverlayDelegate {
  final Function(dartz.Option<ShareAction>) onSelected;
  final _items = ShareAction.values.map((action) => ShareActionWrapper(action)).toList();

  ShareActions({required this.onSelected});

  @override
  double get maxWidth => 130;

  @override
  double get itemHeight => 22;

  @override
  List<ShareActionWrapper> get items => _items;

  @override
  void Function(dartz.Option<ShareActionWrapper> p1) get selectCallback => (result) {
        result.fold(
          () => onSelected(dartz.none()),
          (wrapper) => onSelected(
            dartz.some(wrapper.inner),
          ),
        );
      };

  @override
  FlowyOverlayDelegate? get delegate => this;

  @override
  void didRemove() => onSelected(dartz.none());
}

enum ShareAction {
  markdown,
  copyLink,
}

class ShareActionWrapper extends ActionItem {
  final ShareAction inner;

  ShareActionWrapper(this.inner);

  @override
  Widget? get icon => null;

  @override
  String get name => inner.name;
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
