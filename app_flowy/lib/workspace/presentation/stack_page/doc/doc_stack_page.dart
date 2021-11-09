import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/domain/view_ext.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' as dartz;

import 'doc_page.dart';

class DocStackContext extends HomeStackContext<String, ShareActionWrapper> {
  View _view;
  late IViewListener _listener;
  final ValueNotifier<String> _isUpdated = ValueNotifier<String>("");

  DocStackContext({required View view, Key? key}) : _view = view {
    _listener = getIt<IViewListener>(param1: view);
    _listener.updatedNotifier.addPublishListener((result) {
      result.fold(
        (newView) {
          _view = newView;
          _isUpdated.value = _view.name;
        },
        (error) {},
      );
    });
    _listener.start();
  }

  @override
  Widget get naviTitle => FlowyText.medium(_view.name, fontSize: 12);

  @override
  Widget? Function(BuildContext context) get buildNaviAction => _buildNaviAction;

  @override
  String get identifier => _view.id;

  @override
  HomeStackType get type => _view.stackType();

  @override
  Widget buildWidget() => DocStackPage(_view, key: ValueKey(_view.id));

  @override
  List<NavigationItem> get navigationItems => _makeNavigationItems();

  @override
  ValueNotifier<String> get isUpdated => _isUpdated;

  // List<NavigationItem> get navigationItems => naviStacks.map((stack) {
  //       return NavigationItemImpl(context: stack);
  //     }).toList();

  List<NavigationItem> _makeNavigationItems() {
    return [this];
  }

  @override
  void dispose() {
    _listener.stop();
  }

  Widget _buildNaviAction(BuildContext context) {
    return const DocShareButton();
  }
}

class DocShareButton extends StatelessWidget {
  const DocShareButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double buttonWidth = 60;
    return RoundedTextButton(
      title: 'Share',
      height: 30,
      width: buttonWidth,
      fontSize: 12,
      borderRadius: Corners.s6Border,
      color: Colors.lightBlue,
      onPressed: () {
        final actionList = ShareActions(onSelected: (result) {
          result.fold(() {}, (action) {
            switch (action) {
              case ShareAction.markdown:
                break;
              case ShareAction.copyLink:
                break;
            }
          });
        });
        actionList.show(
          context,
          context,
          anchorDirection: AnchorDirection.bottomWithCenterAligned,
          anchorOffset: Offset(-(buttonWidth / 2), 10),
        );
      },
    );
  }
}

class DocStackPage extends StatefulWidget {
  final View view;
  const DocStackPage(this.view, {Key? key}) : super(key: key);

  @override
  _DocStackPageState createState() => _DocStackPageState();
}

class _DocStackPageState extends State<DocStackPage> {
  @override
  Widget build(BuildContext context) {
    return DocPage(view: widget.view);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant DocStackPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}

class ShareActions with ActionList<ShareActionWrapper> implements FlowyOverlayDelegate {
  final Function(dartz.Option<ShareAction>) onSelected;
  final _items = ShareAction.values.map((action) => ShareActionWrapper(action)).toList();

  ShareActions({
    required this.onSelected,
  });

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
  void didRemove() {
    onSelected(dartz.none());
  }

  @override
  ListOverlayFooter? get footer => null;
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
        return "Markdown";
      case ShareAction.copyLink:
        return "Copy Link";
    }
  }
}
