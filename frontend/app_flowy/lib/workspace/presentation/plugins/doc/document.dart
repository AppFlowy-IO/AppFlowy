library docuemnt_plugin;

export './src/document_page.dart';
export './src/widget/toolbar/history_button.dart';
export './src/widget/toolbar/toolbar_icon_button.dart';
export './src/widget/toolbar/tool_bar.dart';

import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/application/doc/share_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_listener.dart';
import 'package:app_flowy/workspace/application/view/view_service.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-block/entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clipboard/clipboard.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:provider/provider.dart';

import 'src/document_page.dart';

class DocumentPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is View) {
      return DocumentPlugin(pluginType: pluginType, view: data);
    } else {
      throw FlowyPluginException.invalidData;
    }
  }

  @override
  String get menuName => "Doc";

  @override
  PluginType get pluginType => DefaultPlugin.quill.type();

  @override
  ViewDataType get dataType => ViewDataType.Block;
}

class DocumentPlugin implements Plugin {
  late View _view;
  ViewListener? _listener;
  late PluginType _pluginType;

  DocumentPlugin({required PluginType pluginType, required View view, Key? key}) : _view = view {
    _pluginType = pluginType;
    _listener = getIt<ViewListener>(param1: view);
    _listener?.updatedNotifier.addPublishListener((result) {
      result.fold(
        (newView) {
          _view = newView;
          display.notifier!.value = _view.hashCode;
        },
        (error) {},
      );
    });
    _listener?.start();
  }

  @override
  void dispose() {
    _listener?.close();
    _listener = null;
  }

  @override
  PluginDisplay<int> get display => DocumentPluginDisplay(view: _view);

  @override
  PluginType get ty => _pluginType;

  @override
  PluginId get id => _view.id;
}

class DocumentPluginDisplay extends PluginDisplay<int> {
  final PublishNotifier<int> _displayNotifier = PublishNotifier<int>();
  final View _view;

  DocumentPluginDisplay({required View view, Key? key}) : _view = view;

  @override
  Widget buildWidget() => DocumentPage(view: _view, key: ValueKey(_view.id));

  @override
  Widget get leftBarItem => DocumentLeftBarItem(view: _view);

  @override
  Widget? get rightBarItem => DocumentShareButton(view: _view);

  @override
  List<NavigationItem> get navigationItems => _makeNavigationItems();

  @override
  PublishNotifier<int>? get notifier => _displayNotifier;

  List<NavigationItem> _makeNavigationItems() {
    return [
      this,
    ];
  }
}

class DocumentLeftBarItem extends StatefulWidget {
  final View view;

  DocumentLeftBarItem({required this.view, Key? key}) : super(key: ValueKey(view.hashCode));

  @override
  State<DocumentLeftBarItem> createState() => _DocumentLeftBarItemState();
}

class _DocumentLeftBarItemState extends State<DocumentLeftBarItem> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late ViewService service;

  @override
  void initState() {
    service = ViewService(/*view: widget.view*/);
    _focusNode.addListener(_handleFocusChanged);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.text = widget.view.name;

    final theme = context.watch<AppTheme>();
    return IntrinsicWidth(
      key: ValueKey(_controller.text),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        scrollPadding: EdgeInsets.zero,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          isDense: true,
        ),
        style: TextStyle(
          color: theme.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
        // cursorColor: widget.cursorColor,
        // obscureText: widget.enableObscure,
      ),
    );
  }

  void _handleFocusChanged() {
    if (_controller.text.isEmpty) {
      _controller.text = widget.view.name;
      return;
    }

    if (_controller.text != widget.view.name) {
      service.updateView(viewId: widget.view.id, name: _controller.text);
    }
  }
}

class DocumentShareButton extends StatelessWidget {
  final View view;
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

  void _handleExportData(ExportData exportData) {
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
            break;
          case ShareAction.copyLink:
            FlowyAlertDialog(title: LocaleKeys.shareAction_workInProgress.tr()).show(context);
            break;
        }
      });
    });
    actionList.show(
      context,
      context,
      anchorDirection: AnchorDirection.bottomWithCenterAligned,
      anchorOffset: offset,
    );
  }
}

class ShareActions with ActionList<ShareActionWrapper> implements FlowyOverlayDelegate {
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
