import 'package:appflowy/ai/service/appflowy_ai_service.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:flutter/material.dart';

class AskAIActionWrapper extends ActionCell {
  AskAIActionWrapper(this.inner);

  final AskAIAction inner;

  Widget? icon(Color iconColor) => null;

  @override
  String get name => inner.name;
}
