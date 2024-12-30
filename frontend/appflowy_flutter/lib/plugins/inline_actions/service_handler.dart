import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';

abstract class InlineActionsDelegate {
  Future<InlineActionsResult> search(String? search);

  Future<void> dispose() async {}
}
