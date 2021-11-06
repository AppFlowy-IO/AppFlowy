import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart' as dartz;

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      width: 30,
      height: 30,
      child: FlowyTextButton(
        '?',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fillColor: theme.selector,
        mainAxisAlignment: MainAxisAlignment.center,
        radius: BorderRadius.circular(10),
        onPressed: () {
          final actionList = QuestionBubbleActions(onSelected: (action) {});
          actionList.show(
            context,
            context,
            anchorDirection: AnchorDirection.topWithCenterAligned,
          );
        },
      ),
    );
  }
}

class QuestionBubbleActions with ActionList<QuestionBubbleActionWrapper> implements FlowyOverlayDelegate {
  final Function(dartz.Option<QuestionBubbleAction>) onSelected;
  final _items = QuestionBubbleAction.values.map((action) => QuestionBubbleActionWrapper(action)).toList();

  QuestionBubbleActions({
    required this.onSelected,
  });

  @override
  List<QuestionBubbleActionWrapper> get items => _items;

  @override
  void Function(dartz.Option<QuestionBubbleActionWrapper> p1) get selectCallback => (result) {
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
}

enum QuestionBubbleAction {
  whatsNews,
}

class QuestionBubbleActionWrapper extends ActionItemData {
  final QuestionBubbleAction inner;

  QuestionBubbleActionWrapper(this.inner);
  @override
  Widget? get icon => null;

  @override
  String get name => inner.name;
}

extension QuestionBubbleExtension on QuestionBubbleAction {
  String get name {
    switch (this) {
      case QuestionBubbleAction.whatsNews:
        return "What's new";
    }
  }
}
