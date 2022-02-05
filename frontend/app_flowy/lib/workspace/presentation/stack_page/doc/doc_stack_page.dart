import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/application/doc/share_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/domain/view_ext.dart';
import 'package:app_flowy/workspace/infrastructure/repos/view_repo.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/share.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clipboard/clipboard.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:provider/provider.dart';

import 'doc_page.dart';

class DocStackContext extends HomeStackContext<int, ShareActionWrapper> {
  View _view;
  late ViewListener _listener;
  final ValueNotifier<int> _isUpdated = ValueNotifier<int>(0);

  DocStackContext({required View view, Key? key}) : _view = view {
    _listener = getIt<ViewListener>(param1: view);
    _listener.updatedNotifier.addPublishListener((result) {
      result.fold(
        (newView) {
          _view = newView;
          _isUpdated.value = _view.hashCode;
        },
        (error) {},
      );
    });
    _listener.start();
  }

  @override
  Widget get leftBarItem => DocumentLeftBarItem(view: _view);

  @override
  Widget? get rightBarItem => DocumentShareButton(view: _view);

  @override
  String get identifier => _view.id;

  @override
  HomeStackType get type => _view.stackType();

  @override
  Widget buildWidget() => DocPage(view: _view, key: ValueKey(_view.id));

  @override
  List<NavigationItem> get navigationItems => _makeNavigationItems();

  @override
  ValueNotifier<int> get isUpdated => _isUpdated;

  // List<NavigationItem> get navigationItems => naviStacks.map((stack) {
  //       return NavigationItemImpl(context: stack);
  //     }).toList();

  List<NavigationItem> _makeNavigationItems() {
    return [
      this,
    ];
  }

  @override
  void dispose() {
    _listener.close();
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
  late ViewRepository repo;

  @override
  void initState() {
    repo = ViewRepository(view: widget.view);
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
      repo.updateView(name: _controller.text);
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
            showWorkInProgressDialog(context);
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

  void showWorkInProgressDialog(BuildContext context) {
    FlowyAlertDialog(title: LocaleKeys.shareAction_workInProgress.tr()).show(context);
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
